package common

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ec2"
	"github.com/aws/aws-sdk-go-v2/service/ec2/types"
	terratest_aws "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestConfig holds common configuration for tests
type TestConfig struct {
	TerraformDir string
	AWSRegion    string
	Prefix       string
	UniqueID     string
}

// NewTestConfig creates a new test configuration with a unique ID
func NewTestConfig(terraformDir string) *TestConfig {
	// Use time-based unique ID instead of deprecated rand.Seed
	uniqueID := fmt.Sprintf("test-%d", time.Now().UnixNano()%100000)

	return &TestConfig{
		TerraformDir: terraformDir,
		AWSRegion:    "us-east-1",
		Prefix:       fmt.Sprintf("landandbay-%s", uniqueID),
		UniqueID:     uniqueID,
	}
}

// GetTerraformOptions returns default terraform options for testing
func (tc *TestConfig) GetTerraformOptions(vars map[string]interface{}) *terraform.Options {
	defaultVars := map[string]interface{}{
		"prefix":     tc.Prefix,
		"aws_region": tc.AWSRegion,
		// Test-specific overrides
		"create_vpc":             true,
		"create_public_subnets":  true,
		"create_private_subnets": true,
		"create_db_subnets":      true,
		"enable_ssr":             false, // Disable SSR for most tests to simplify
		// Use minimal resources for testing
		"db_allocated_storage": 20,
		"db_instance_class":    "db.t4g.micro",
		// Required for some modules but not needed for most tests
		"route53_zone_id":     "Z123456789",
		"domain_name":         fmt.Sprintf("%s.example.com", tc.UniqueID),
		"acm_certificate_arn": fmt.Sprintf("arn:aws:acm:us-east-1:123456789012:certificate/%s", tc.UniqueID),
		"alert_email":         "test@example.com",
		"db_password":         "testpassword123!",
		"app_db_password":     "apppassword123!",
	}

	// Merge with provided vars (provided vars override defaults)
	for k, v := range vars {
		defaultVars[k] = v
	}

	return &terraform.Options{
		TerraformDir: tc.TerraformDir,
		Vars:         defaultVars,
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": tc.AWSRegion,
		},
	}
}

// GetModuleTerraformOptions returns terraform options for testing individual modules
func (tc *TestConfig) GetModuleTerraformOptions(modulePath string, vars map[string]interface{}) *terraform.Options {
	opts := tc.GetTerraformOptions(vars)
	opts.TerraformDir = modulePath
	return opts
}

// GetSubnetById gets a subnet by ID using AWS SDK v2 directly
func GetSubnetById(t *testing.T, subnetID, region string) *types.Subnet {
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	assert.NoError(t, err)

	svc := ec2.NewFromConfig(cfg)
	result, err := svc.DescribeSubnets(context.TODO(), &ec2.DescribeSubnetsInput{
		SubnetIds: []string{subnetID},
	})
	assert.NoError(t, err)
	assert.Len(t, result.Subnets, 1)

	return &result.Subnets[0]
}

// GetSecurityGroupById gets a security group by ID using AWS SDK v2 directly
func GetSecurityGroupById(t *testing.T, sgID, region string) *types.SecurityGroup {
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	assert.NoError(t, err)

	svc := ec2.NewFromConfig(cfg)
	result, err := svc.DescribeSecurityGroups(context.TODO(), &ec2.DescribeSecurityGroupsInput{
		GroupIds: []string{sgID},
	})
	assert.NoError(t, err)
	assert.Len(t, result.SecurityGroups, 1)

	return &result.SecurityGroups[0]
}

// GetInternetGatewaysForVpc gets internet gateways for a VPC using AWS SDK v2 directly
func GetInternetGatewaysForVpc(t *testing.T, vpcID, region string) []types.InternetGateway {
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	assert.NoError(t, err)

	svc := ec2.NewFromConfig(cfg)
	result, err := svc.DescribeInternetGateways(context.TODO(), &ec2.DescribeInternetGatewaysInput{
		Filters: []types.Filter{
			{
				Name:   aws.String("attachment.vpc-id"),
				Values: []string{vpcID},
			},
		},
	})
	assert.NoError(t, err)

	return result.InternetGateways
}

// GetEc2InstanceById gets an EC2 instance by ID using AWS SDK v2 directly
func GetEc2InstanceById(t *testing.T, instanceID, region string) *types.Instance {
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	assert.NoError(t, err)

	svc := ec2.NewFromConfig(cfg)
	result, err := svc.DescribeInstances(context.TODO(), &ec2.DescribeInstancesInput{
		InstanceIds: []string{instanceID},
	})
	assert.NoError(t, err)
	assert.Len(t, result.Reservations, 1)
	assert.Len(t, result.Reservations[0].Instances, 1)

	return &result.Reservations[0].Instances[0]
}

// ValidateAWSResource checks if an AWS resource exists
func ValidateAWSResource(t *testing.T, awsRegion, resourceType, resourceID string) {
	switch resourceType {
	case "vpc":
		vpc := terratest_aws.GetVpcById(t, resourceID, awsRegion)
		assert.NotNil(t, vpc)
		// Note: VPC state validation removed as Terratest VPC struct doesn't expose State field
	case "subnet":
		subnet := GetSubnetById(t, resourceID, awsRegion)
		assert.NotNil(t, subnet)
		assert.Equal(t, types.SubnetStateAvailable, subnet.State)
	case "security_group":
		sg := GetSecurityGroupById(t, resourceID, awsRegion)
		assert.NotNil(t, sg)
	case "load_balancer":
		// Load balancer validation would go here
		// Note: Terratest doesn't have direct ALB support, so we'd use AWS SDK directly
	}
}

// ValidateResourceTags checks if resources have the expected tags
func ValidateResourceTags(t *testing.T, tags map[string]string, expectedTags map[string]string) {
	for key, expectedValue := range expectedTags {
		actualValue, exists := tags[key]
		assert.True(t, exists, fmt.Sprintf("Expected tag %s not found", key))
		assert.Equal(t, expectedValue, actualValue, fmt.Sprintf("Tag %s has incorrect value", key))
	}
}

// ValidateResourceNaming checks if resources follow naming conventions
func ValidateResourceNaming(t *testing.T, resourceName, prefix, expectedSuffix string) {
	assert.True(t, strings.HasPrefix(resourceName, prefix),
		fmt.Sprintf("Resource %s should start with prefix %s", resourceName, prefix))

	if expectedSuffix != "" {
		assert.True(t, strings.HasSuffix(resourceName, expectedSuffix),
			fmt.Sprintf("Resource %s should end with suffix %s", resourceName, expectedSuffix))
	}
}

// GetVPCCIDRBlocks returns CIDR blocks for testing
func GetVPCCIDRBlocks() map[string]string {
	return map[string]string{
		"vpc_cidr":                 "10.0.0.0/16",
		"public_subnet_a_cidr":     "10.0.1.0/24",
		"public_subnet_b_cidr":     "10.0.2.0/24",
		"private_subnet_a_cidr":    "10.0.3.0/24",
		"private_subnet_b_cidr":    "10.0.4.0/24",
		"private_db_subnet_a_cidr": "10.0.5.0/24",
		"private_db_subnet_b_cidr": "10.0.6.0/24",
	}
}

// CleanupResources performs cleanup for failed tests
func CleanupResources(t *testing.T, terraformOptions *terraform.Options) {
	// This will run terraform destroy
	defer terraform.Destroy(t, terraformOptions)
}

// SkipIfShortTest skips tests that require AWS resources when running with -short flag
func SkipIfShortTest(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test that requires AWS resources in short mode")
	}
}
