# Terraform Testing Suite

This directory contains comprehensive unit and integration tests for the Coalition Builder Terraform infrastructure using [Terratest](https://terratest.gruntwork.io/).

## 📁 Test Structure

```
tests/
├── common/
│   └── test_helpers.go          # Shared test utilities and configuration
├── modules/
│   ├── networking_test.go       # Tests for networking module
│   ├── compute_test.go          # Tests for compute module
│   ├── security_test.go         # Tests for security module
│   └── database_test.go         # Tests for database module
├── integration/
│   └── full_stack_test.go       # End-to-end infrastructure tests
├── go.mod                       # Go module dependencies
├── Makefile                     # Test runner and utilities
└── README.md                    # This file
```

## 🧪 Test Types

### Unit Tests (`modules/`)

Test individual Terraform modules in isolation:

- **Networking Tests**: VPC, subnets, routing, VPC endpoints
- **Compute Tests**: ECS cluster, task definitions, ECR repositories, bastion host
- **Security Tests**: Security groups, WAF, IAM roles and policies
- **Database Tests**: RDS instance, subnet groups, parameter groups, encryption

### Integration Tests (`integration/`)

Test complete infrastructure deployments:

- **Full Stack Deployment**: Complete infrastructure with all modules
- **SSR Configuration**: Tests with Server-Side Rendering enabled/disabled
- **Security Configuration**: Validates security group rules and restrictions
- **Resource Tagging**: Ensures proper resource tagging
- **Budget Monitoring**: Tests cost monitoring setup

## 🚀 Quick Start

### Prerequisites

1. **Go 1.24+** installed
2. **AWS CLI** configured with appropriate credentials
3. **Terraform** installed (version 1.12.1+)
4. **Make** (optional, for convenience commands)

### Setup

```bash
# Navigate to tests directory
cd terraform/tests

# Install dependencies
go mod download

# Verify AWS configuration
aws sts get-caller-identity

# Verify Terraform installation
terraform version
```

## 💻 Running Tests Locally

### Quick Test (No AWS Resources)

The fastest way to verify tests work without creating AWS resources:

```bash
# Run all tests in short mode (skips AWS resource creation)
go test -short ./...

# Or with make
make test-all-short
```

**What this does:**

- ✅ Compiles all test code
- ✅ Validates test logic and structure
- ✅ Skips actual AWS resource creation
- ✅ Runs in ~30 seconds
- ✅ No AWS costs incurred

### Local Development Testing

For comprehensive testing during development:

```bash
# 1. Test a specific module without AWS resources (free)
go test -short -v -run TestNetworkingModule ./modules/

# 2. Test a specific function in detail (free)
go test -v -run TestNetworkingModuleCreatesVPC ./modules/

# 3. Test with actual AWS resources (~$1, 15-20 minutes)
go test -v -timeout 30m -run TestNetworkingModuleCreatesVPC ./modules/

# 4. Test all modules with AWS resources (~$4, 30-45 minutes)
make test-unit
```

### Testing Individual Modules

```bash
# Test networking module (~$1, 15 minutes)
make test-networking
# Or: go test -v -timeout 20m -run TestNetworkingModule ./modules/

# Test compute module (~$1, 20 minutes)
make test-compute
# Or: go test -v -timeout 20m -run TestComputeModule ./modules/

# Test security module (~$1, 10 minutes)
make test-security
# Or: go test -v -timeout 20m -run TestSecurityModule ./modules/

# Test database module (~$1, 20 minutes)
make test-database
# Or: go test -v -timeout 20m -run TestDatabaseModule ./modules/
```

### Full Integration Testing

**⚠️ Creates complete AWS infrastructure (~$3-5 per run)**

```bash
# Test complete infrastructure deployment
make test-integration

# Or test specific integration scenarios
go test -v -timeout 45m -run TestFullStackDeploymentWithoutSSR ./integration/
go test -v -timeout 45m -run TestFullStackDeploymentWithSSR ./integration/
```

### Local Test Configuration

#### Environment Setup

```bash
# Required: AWS credentials
export AWS_REGION=us-east-1
export AWS_PROFILE=your-dev-profile

# Optional: Custom test settings
export TEST_TIMEOUT=30m
export TERRATEST_TERRAFORM=terraform

# Verify setup
aws sts get-caller-identity
terraform version
```

#### Test Isolation

Each test run creates uniquely named resources:

```bash
# Example resource names created during tests:
# - VPC: coalition-test-12345-vpc
# - Cluster: coalition-test-12345-cluster
# - Database: coalition-test-12345-postgres
```

#### Cleanup

Tests automatically clean up resources:

```bash
# Automatic cleanup happens in defer statements
defer common.CleanupResources(t, terraformOptions)

# Manual cleanup if needed
make clean

# Check for leftover resources
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=coalition-test-*"
```

### Debugging Failed Tests

```bash
# Run with maximum verbosity
go test -v -timeout 30m -run TestSpecificFailingTest ./modules/

# Debug Terraform state
export TF_LOG=DEBUG
go test -v -run TestNetworkingModule ./modules/

# Keep resources for manual inspection (remove defer cleanup)
# Comment out: defer common.CleanupResources(t, terraformOptions)
```

### Cost Optimization for Local Testing

1. **Use Short Mode**: `go test -short ./...` (free)
2. **Test Individual Modules**: Each module costs ~$1 per run
3. **Avoid Frequent Integration Tests**: Full stack tests cost ~$3-5 per run
4. **Use Smaller Instances**: Tests use `t4g.micro` and minimal storage
5. **Automatic Cleanup**: Resources destroyed after 30 minutes max

**💡 Cost Breakdown:**

- **Security Module**: ~$1 (WAF, security groups, 10 min)
- **Networking Module**: ~$1 (VPC endpoints, minimal data transfer, 15 min)
- **Compute Module**: ~$1 (t4g.nano bastion, ECS cluster, 20 min)
- **Database Module**: ~$1 (db.t4g.micro RDS, 20GB storage, 20 min)
- **Integration Test**: ~$3-5 (all resources + ALB, 45 min)

### Local vs CI Testing

| Mode              | Resources Created       | Time   | Cost       | Use Case              |
| ----------------- | ----------------------- | ------ | ---------- | --------------------- |
| `go test -short`  | None                    | 30s    | $0         | Quick validation      |
| Individual module | Single module resources | 10-20m | ~$1        | Development           |
| All modules       | All individual modules  | 30-45m | ~$4        | Pre-commit validation |
| Integration test  | Full infrastructure     | 45m    | ~$3-5      | Pre-production        |
| CI/CD             | Based on trigger        | Varies | Controlled | Automated validation  |

**Cost Calculation Method:**

- Based on AWS us-east-1 pricing (December 2024)
- Includes actual resource costs (RDS, WAF, bastion instance, ALB)
- Minimal data transfer and API call charges included
- 10-20% safety margin for regional variations and overruns
- Free tier eligible resources (VPC, subnets, security groups) excluded

**Example**: Database module uses db.t4g.micro ($0.016/hour) + 20GB gp3 storage ($0.08/month) for 20 minutes = ~$0.006 + safety margin = ~$1 total.

### Running Tests

#### Unit Tests (Fast, No AWS Resources)

```bash
# Run all unit tests in short mode (no AWS resources created)
make test-all-short

# Or manually:
go test -short ./...
```

#### Unit Tests (With AWS Resources)

```bash
# Run all module tests
make test-unit

# Run specific module tests
make test-networking
make test-compute
make test-security
make test-database
```

#### Integration Tests

```bash
# Run integration tests (creates full infrastructure)
make test-integration

# Run specific integration test
go test -v -run TestFullStackDeploymentWithoutSSR ./integration/
```

## 📋 Test Commands

### Using Make (Recommended)

```bash
# Show all available commands
make help

# Setup development environment
make dev-setup

# Run pre-commit checks
make pre-commit

# Run all tests
make test-all

# Run tests without creating AWS resources
make test-all-short

# Clean up test artifacts
make clean
```

### Using Go Directly

```bash
# Run all tests in short mode
go test -short ./...

# Run all tests with AWS resources (longer)
go test ./...

# Run specific test
go test -v -run TestNetworkingModuleCreatesVPC ./modules/

# Run tests with custom timeout
go test -timeout 30m ./...
```

## 🔧 Configuration

### Environment Variables

```bash
# AWS Configuration
export AWS_REGION=us-east-1
export AWS_PROFILE=your-profile

# Test Configuration
export TEST_TIMEOUT=30m
```

### Test Configuration

Tests use unique prefixes to avoid conflicts:

```go
testConfig := common.NewTestConfig("../modules/networking")
// Creates prefix like "coalition-test-12345"
```

## 🧩 Test Modules

### Networking Module Tests

- ✅ VPC creation with correct CIDR blocks
- ✅ Public subnet creation in multiple AZs
- ✅ Private subnet creation for applications
- ✅ Database subnet creation with isolation
- ✅ Internet Gateway attachment
- ✅ Route table configuration
- ✅ VPC endpoints for AWS services
- ✅ Resource naming conventions
- ✅ Resource tagging

### Compute Module Tests

- ✅ ECR repository creation for API and SSR
- ✅ ECS cluster creation
- ✅ IAM roles and policies for ECS tasks
- ✅ Task definition with/without SSR
- ✅ Bastion host deployment
- ✅ Resource constraints validation
- ✅ Security group assignments

### Security Module Tests

- ✅ ALB security group with HTTP/HTTPS rules
- ✅ Application security group with restricted access
- ✅ Database security group with PostgreSQL access
- ✅ Bastion security group with SSH restrictions
- ✅ WAF web ACL creation
- ✅ Security group rule references
- ✅ Egress rule restrictions

### Database Module Tests

- ✅ RDS PostgreSQL instance creation
- ✅ DB subnet group configuration
- ✅ Parameter group for PostgreSQL 16
- ✅ Secrets Manager integration
- ✅ Backup configuration
- ✅ Storage encryption
- ✅ PostGIS extension support
- ✅ Resource naming and tagging

### Integration Tests

- ✅ Full stack deployment without SSR
- ✅ Full stack deployment with SSR
- ✅ Deployment with existing VPC
- ✅ Security configuration validation
- ✅ Resource tagging across modules
- ✅ Budget monitoring setup

## 🔍 Test Patterns

### Resource Validation

```go
// Validate AWS resource exists and has correct properties
vpc := aws.GetVpcById(t, vpcID, testConfig.AWSRegion)
assert.Equal(t, "10.0.0.0/16", vpc.CidrBlock)
assert.Equal(t, "available", vpc.State)
```

### Resource Naming

```go
// Validate naming conventions
common.ValidateResourceNaming(t, resourceName, testConfig.Prefix, "expected-suffix")
```

### Resource Tagging

```go
// Validate required tags
expectedTags := map[string]string{
    "Name": fmt.Sprintf("%s-vpc", testConfig.Prefix),
    "Environment": "test",
}
common.ValidateResourceTags(t, vpc.Tags, expectedTags)
```

### Cleanup

```go
// Automatic cleanup with defer
defer common.CleanupResources(t, terraformOptions)
```

## ⚠️ Important Notes

### Cost Management

- **Short Mode**: Use `-short` flag to skip AWS resource creation
- **Timeouts**: Tests have 30-minute default timeout
- **Cleanup**: Resources are automatically destroyed after tests
- **Parallel**: Avoid running multiple integration tests simultaneously

### AWS Permissions

Tests require AWS permissions to create:

- VPC and networking resources
- ECS clusters and services
- RDS databases
- Security groups
- IAM roles and policies
- ECR repositories
- Load balancers

### Test Isolation

- Each test uses unique resource prefixes
- Tests clean up automatically with `defer`
- Use different AWS regions for parallel test runs

## 🚨 Troubleshooting

### Common Issues

#### AWS Credentials

```bash
# Verify credentials
aws sts get-caller-identity

# Configure if needed
aws configure
```

#### Test Timeouts

```bash
# Increase timeout for slow tests
go test -timeout 45m ./...
```

#### Resource Conflicts

```bash
# Clean up any leftover resources
make clean

# Check for existing resources with test prefix
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=coalition-test-*"
```

#### Permission Errors

Ensure your AWS user/role has sufficient permissions:

- EC2 full access
- RDS full access
- ECS full access
- IAM role creation
- ECR repository management

### Debug Mode

```bash
# Run with verbose output
go test -v ./...

# Run single test for debugging
go test -v -run TestSpecificTest ./modules/
```

## 📈 CI/CD Integration

### GitHub Actions

```yaml
name: Terraform Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v4
        with:
          go-version: "1.21"
      - name: Run short tests
        run: |
          cd terraform/tests
          make ci-test
```

### Local Development

```bash
# Setup git hooks for testing
echo "make pre-commit" > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## 🤝 Contributing

### Adding New Tests

1. **Module Tests**: Add to appropriate `modules/*_test.go` file
2. **Integration Tests**: Add to `integration/full_stack_test.go`
3. **Helpers**: Update `common/test_helpers.go` for shared functionality

### Test Guidelines

- ✅ Use descriptive test names
- ✅ Include cleanup with `defer`
- ✅ Validate both success and failure cases
- ✅ Use `common.SkipIfShortTest(t)` for AWS resource tests
- ✅ Follow Go testing conventions
- ✅ Add documentation for complex test scenarios

### Example Test Structure

```go
func TestNewFeature(t *testing.T) {
    common.SkipIfShortTest(t)

    testConfig := common.NewTestConfig("../modules/mymodule")
    testVars := map[string]interface{}{
        "feature_enabled": true,
    }

    terraformOptions := testConfig.GetModuleTerraformOptions("../modules/mymodule", testVars)
    defer common.CleanupResources(t, terraformOptions)

    terraform.InitAndApply(t, terraformOptions)

    // Validate outputs
    output := terraform.Output(t, terraformOptions, "feature_output")
    assert.NotEmpty(t, output)
}
```

## 🔧 Technical Details

### AWS SDK Integration

The test suite uses **AWS SDK for Go v2** for direct AWS resource validation:

```go
// Example: Validating EC2 instances
cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
svc := ec2.NewFromConfig(cfg)
result, err := svc.DescribeInstances(context.TODO(), &ec2.DescribeInstancesInput{
    InstanceIds: []string{instanceID},
})
```

**Key Features:**

- Modern context-based API calls
- Improved type safety with enum types
- Better performance and memory efficiency
- Modular service imports

### Dependencies

**Core Testing Framework:**

- `github.com/gruntwork-io/terratest` v0.49.0
- `github.com/stretchr/testify` v1.10.0

**AWS SDK v2:**

- `github.com/aws/aws-sdk-go-v2` v1.36.3
- `github.com/aws/aws-sdk-go-v2/config` v1.29.14
- `github.com/aws/aws-sdk-go-v2/service/ec2` v1.224.0

### Test Helper Functions

Custom AWS SDK v2 helpers in `common/test_helpers.go`:

```go
// Get subnet by ID using AWS SDK v2
func GetSubnetById(t *testing.T, subnetID, region string) *types.Subnet

// Get security group by ID using AWS SDK v2
func GetSecurityGroupById(t *testing.T, sgID, region string) *types.SecurityGroup

// Get EC2 instance by ID using AWS SDK v2
func GetEc2InstanceById(t *testing.T, instanceID, region string) *types.Instance

// Get internet gateways for VPC using AWS SDK v2
func GetInternetGatewaysForVpc(t *testing.T, vpcID, region string) []types.InternetGateway
```

## 📚 Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Go Testing Package](https://golang.org/pkg/testing/)
- [AWS SDK for Go v2](https://aws.github.io/aws-sdk-go-v2/docs/)
- [AWS SDK v2 EC2 Service](https://pkg.go.dev/github.com/aws/aws-sdk-go-v2/service/ec2)
- [Terraform Testing Best Practices](https://www.terraform.io/docs/extend/testing/index.html)
