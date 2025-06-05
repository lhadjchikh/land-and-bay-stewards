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
		TerraformDir:    tc.TerraformDir,
		TerraformBinary: "terraform", // Explicitly use terraform instead of auto-detecting tofu
		Vars:            defaultVars,
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION":  tc.AWSRegion,
			"TERRATEST_TERRAFORM": "terraform", // Force Terratest to use terraform
		},
	}
}

// GetModuleTerraformOptions returns terraform options for testing individual modules
func (tc *TestConfig) GetModuleTerraformOptions(modulePath string, vars map[string]interface{}) *terraform.Options {
	// Get minimal variables suitable for individual module testing
	moduleVars := tc.getModuleSpecificVars(modulePath, vars)

	return &terraform.Options{
		TerraformDir:    modulePath,
		TerraformBinary: "terraform", // Explicitly use terraform instead of auto-detecting tofu
		Vars:            moduleVars,
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION":  tc.AWSRegion,
			"TERRATEST_TERRAFORM": "terraform", // Force Terratest to use terraform
		},
	}
}

// getModuleSpecificVars returns only the variables needed for a specific module
func (tc *TestConfig) getModuleSpecificVars(
	modulePath string,
	additionalVars map[string]interface{},
) map[string]interface{} {
	var baseVars map[string]interface{}

	// Add module-specific variables based on the module path
	switch {
	case strings.Contains(modulePath, "/security"):
		// Security module variables (does not include aws_region)
		baseVars = map[string]interface{}{
			"prefix":                tc.Prefix,
			"vpc_id":                "vpc-12345678",
			"allowed_bastion_cidrs": []string{"10.0.0.0/8"},
			"database_subnet_cidrs": []string{"10.0.5.0/24", "10.0.6.0/24"},
		}
	case strings.Contains(modulePath, "/networking"):
		// Networking module variables (includes aws_region)
		baseVars = map[string]interface{}{
			"prefix":                 tc.Prefix,
			"aws_region":             tc.AWSRegion,
			"create_vpc":             true,
			"create_public_subnets":  true,
			"create_private_subnets": true,
			"create_db_subnets":      true,
		}
	case strings.Contains(modulePath, "/database"):
		// Database module variables (includes aws_region)
		baseVars = map[string]interface{}{
			"prefix":               tc.Prefix,
			"aws_region":           tc.AWSRegion,
			"db_subnet_ids":        []string{"subnet-12345", "subnet-67890"},
			"db_security_group_id": "sg-db123",
			"db_allocated_storage": 20,
			"db_instance_class":    "db.t4g.micro",
			"db_password":          "testpassword123!",
			"db_name":              "testdb",
			"db_username":          "testuser",
			"app_db_username":      "appuser",
		}
	case strings.Contains(modulePath, "/compute"):
		// Compute module variables (includes aws_region)
		baseVars = map[string]interface{}{
			"prefix":                    tc.Prefix,
			"aws_region":                tc.AWSRegion,
			"private_subnet_ids":        []string{"subnet-12345", "subnet-67890"},
			"public_subnet_id":          "subnet-public",
			"app_security_group_id":     "sg-app123",
			"bastion_security_group_id": "sg-bastion123",
			"db_url_secret_arn":         "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-db-url",
			"secret_key_secret_arn":     "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-secret-key",
			"secrets_kms_key_arn":       "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
			"bastion_key_name":          "test-key",
			"bastion_public_key":        "",
			"create_new_key_pair":       false,
			"container_port":            8000,
			"domain_name":               fmt.Sprintf("%s.example.com", tc.UniqueID),
			"enable_ssr":                false,
			"health_check_path":         "/api/health/",
			"api_target_group_arn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:" +
				"targetgroup/test-api/1234567890123456",
			"ssr_target_group_arn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:" +
				"targetgroup/test-ssr/1234567890123456",
		}
	default:
		// Default fallback for unrecognized modules
		baseVars = map[string]interface{}{
			"prefix":     tc.Prefix,
			"aws_region": tc.AWSRegion,
		}
	}

	// Merge with additional vars (additional vars override base vars)
	for k, v := range additionalVars {
		baseVars[k] = v
	}

	return baseVars
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
func ValidateResourceTags(t *testing.T, tags, expectedTags map[string]string) {
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

// GetNetworkingTestVars creates test variables with CIDR blocks merged
func GetNetworkingTestVars() map[string]interface{} {
	cidrBlocks := GetVPCCIDRBlocks()
	testVars := make(map[string]interface{})

	// Merge CIDR blocks into test variables
	for k, v := range cidrBlocks {
		testVars[k] = v
	}

	return testVars
}

// GetIntegrationTestVars creates test variables with CIDR blocks for integration tests
func GetIntegrationTestVars() map[string]interface{} {
	cidrBlocks := GetVPCCIDRBlocks()
	testVars := make(map[string]interface{})

	// Merge CIDR blocks into test variables
	for k, v := range cidrBlocks {
		testVars[k] = v
	}

	return testVars
}

// CleanupResources performs cleanup for failed tests
func CleanupResources(t *testing.T, terraformOptions *terraform.Options) {
	// This will run terraform destroy
	terraform.Destroy(t, terraformOptions)
}

// SkipIfShortTest skips tests that require AWS resources when running with -short flag
func SkipIfShortTest(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test that requires AWS resources in short mode")
	}
}
