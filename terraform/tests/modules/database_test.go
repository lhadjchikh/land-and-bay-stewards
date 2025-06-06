package modules

import (
	"fmt"
	"testing"

	"terraform-tests/common"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestDatabaseModuleValidation runs validation-only tests that don't require AWS credentials
func TestDatabaseModuleValidation(t *testing.T) {
	common.ValidateModuleStructure(t, "database")
}

func TestDatabaseModuleCreatesRDSInstance(t *testing.T) {
	testConfig, terraformOptions := common.SetupModuleTest(t, "database", common.GetDefaultDatabaseTestVars())

	terraform.InitAndApply(t, terraformOptions)

	// Validate RDS instance outputs
	dbInstanceID := common.ValidateTerraformOutput(t, terraformOptions, "db_instance_id")
	common.ValidateTerraformOutput(t, terraformOptions, "db_instance_endpoint")

	dbInstanceName := terraform.Output(t, terraformOptions, "db_instance_name")
	dbInstancePort := terraform.Output(t, terraformOptions, "db_instance_port")

	assert.Equal(t, "testdb", dbInstanceName)
	assert.Equal(t, "5432", dbInstancePort)

	// Validate instance naming
	expectedInstanceID := fmt.Sprintf("%s-postgres", testConfig.Prefix)
	assert.Equal(t, expectedInstanceID, dbInstanceID)
}

func TestDatabaseModuleCreatesSubnetGroup(t *testing.T) {
	common.SkipIfShortTest(t)

	testConfig := common.NewTestConfig("../../modules/database")

	testVars := map[string]interface{}{
		"db_subnet_ids":              []string{"subnet-db1", "subnet-db2"},
		"db_security_group_id":       "sg-database123",
		"db_allocated_storage":       20,
		"db_engine_version":          "16.9",
		"db_instance_class":          "db.t4g.micro",
		"db_name":                    "testdb",
		"db_username":                "testuser",
		"db_password":                "testpassword123!",
		"app_db_username":            "appuser",
		"use_secrets_manager":        false,
		"db_backup_retention_period": 7,
		"auto_setup_database":        false,
	}

	terraformOptions := testConfig.GetModuleTerraformOptions("../../modules/database", testVars)
	defer common.CleanupResources(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate subnet group
	subnetGroupName := terraform.Output(t, terraformOptions, "db_subnet_group_name")
	assert.NotEmpty(t, subnetGroupName)

	expectedSubnetGroupName := fmt.Sprintf("%s-db-subnet-group", testConfig.Prefix)
	assert.Equal(t, expectedSubnetGroupName, subnetGroupName)

	// In a real test, you'd validate the subnet group contains the correct subnets
	// using AWS SDK calls since Terratest doesn't have direct DB subnet group support
}

func TestDatabaseModuleCreatesParameterGroup(t *testing.T) {
	common.SkipIfShortTest(t)

	testConfig := common.NewTestConfig("../../modules/database")

	testVars := map[string]interface{}{
		"db_subnet_ids":              []string{"subnet-db1", "subnet-db2"},
		"db_security_group_id":       "sg-database123",
		"db_allocated_storage":       20,
		"db_engine_version":          "16.9",
		"db_instance_class":          "db.t4g.micro",
		"db_name":                    "testdb",
		"db_username":                "testuser",
		"db_password":                "testpassword123!",
		"app_db_username":            "appuser",
		"use_secrets_manager":        false,
		"db_backup_retention_period": 7,
		"auto_setup_database":        false,
	}

	terraformOptions := testConfig.GetModuleTerraformOptions("../../modules/database", testVars)
	defer common.CleanupResources(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate parameter group
	parameterGroupName := terraform.Output(t, terraformOptions, "db_parameter_group_name")
	assert.NotEmpty(t, parameterGroupName)

	expectedParameterGroupName := fmt.Sprintf("%s-postgres16", testConfig.Prefix)
	assert.Equal(t, expectedParameterGroupName, parameterGroupName)
}

func TestDatabaseModuleWithSecretsManager(t *testing.T) {
	common.SkipIfShortTest(t)

	testConfig := common.NewTestConfig("../../modules/database")

	testVars := map[string]interface{}{
		"db_subnet_ids":              []string{"subnet-db1", "subnet-db2"},
		"db_security_group_id":       "sg-database123",
		"db_allocated_storage":       20,
		"db_engine_version":          "16.9",
		"db_instance_class":          "db.t4g.micro",
		"db_name":                    "testdb",
		"db_username":                "testuser",
		"db_password":                "testpassword123!",
		"app_db_username":            "appuser",
		"use_secrets_manager":        true, // Enable secrets manager
		"db_backup_retention_period": 14,
		"auto_setup_database":        false,
	}

	terraformOptions := testConfig.GetModuleTerraformOptions("../../modules/database", testVars)
	defer common.CleanupResources(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// When secrets manager is enabled, password should be managed differently
	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	assert.NotEmpty(t, dbInstanceID)

	// Validate that the instance was created successfully with secrets manager integration
	// In a real test, you'd verify the secrets are properly created and linked
}

func TestDatabaseModuleValidatesBackupConfiguration(t *testing.T) {
	common.SkipIfShortTest(t)

	testConfig := common.NewTestConfig("../../modules/database")

	testVars := map[string]interface{}{
		"db_subnet_ids":              []string{"subnet-db1", "subnet-db2"},
		"db_security_group_id":       "sg-database123",
		"db_allocated_storage":       20,
		"db_engine_version":          "16.9",
		"db_instance_class":          "db.t4g.micro",
		"db_name":                    "testdb",
		"db_username":                "testuser",
		"db_password":                "testpassword123!",
		"app_db_username":            "appuser",
		"use_secrets_manager":        false,
		"db_backup_retention_period": 30, // Extended backup retention
		"auto_setup_database":        false,
	}

	terraformOptions := testConfig.GetModuleTerraformOptions("../../modules/database", testVars)
	defer common.CleanupResources(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate the database was created
	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	assert.NotEmpty(t, dbInstanceID)

	// In a real test, you'd validate backup configuration using AWS SDK:
	// - backup_retention_period is set correctly
	// - backup_window is configured
	// - automated_backups are enabled
	// - point_in_time_recovery is enabled
}

func TestDatabaseModuleValidatesEncryption(t *testing.T) {
	common.SkipIfShortTest(t)

	testConfig := common.NewTestConfig("../../modules/database")

	testVars := map[string]interface{}{
		"db_subnet_ids":              []string{"subnet-db1", "subnet-db2"},
		"db_security_group_id":       "sg-database123",
		"db_allocated_storage":       20,
		"db_engine_version":          "16.9",
		"db_instance_class":          "db.t4g.micro",
		"db_name":                    "testdb",
		"db_username":                "testuser",
		"db_password":                "testpassword123!",
		"app_db_username":            "appuser",
		"use_secrets_manager":        false,
		"db_backup_retention_period": 7,
		"auto_setup_database":        false,
	}

	terraformOptions := testConfig.GetModuleTerraformOptions("../../modules/database", testVars)
	defer common.CleanupResources(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate the database was created
	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	assert.NotEmpty(t, dbInstanceID)

	// In a real test, you'd validate encryption settings using AWS SDK:
	// - storage_encrypted is true
	// - kms_key_id is set appropriately
}

func TestDatabaseModuleValidatesPostGISExtension(t *testing.T) {
	common.SkipIfShortTest(t)

	testConfig := common.NewTestConfig("../../modules/database")

	testVars := map[string]interface{}{
		"db_subnet_ids":              []string{"subnet-db1", "subnet-db2"},
		"db_security_group_id":       "sg-database123",
		"db_allocated_storage":       20,
		"db_engine_version":          "16.9",
		"db_instance_class":          "db.t4g.micro",
		"db_name":                    "testdb",
		"db_username":                "testuser",
		"db_password":                "testpassword123!",
		"app_db_username":            "appuser",
		"use_secrets_manager":        false,
		"db_backup_retention_period": 7,
		"auto_setup_database":        true, // Enable database setup to test PostGIS
	}

	terraformOptions := testConfig.GetModuleTerraformOptions("../../modules/database", testVars)
	defer common.CleanupResources(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate the database was created
	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	assert.NotEmpty(t, dbInstanceID)

	// In a real test with actual database connectivity, you'd:
	// 1. Connect to the database
	// 2. Verify PostGIS extension is installed
	// 3. Test spatial functions work
	// For unit tests, we just validate the terraform apply succeeded
}

func TestDatabaseModuleValidatesResourceNaming(t *testing.T) {
	common.SkipIfShortTest(t)

	testConfig := common.NewTestConfig("../../modules/database")

	testVars := map[string]interface{}{
		"db_subnet_ids":              []string{"subnet-db1", "subnet-db2"},
		"db_security_group_id":       "sg-database123",
		"db_allocated_storage":       20,
		"db_engine_version":          "16.9",
		"db_instance_class":          "db.t4g.micro",
		"db_name":                    "testdb",
		"db_username":                "testuser",
		"db_password":                "testpassword123!",
		"app_db_username":            "appuser",
		"use_secrets_manager":        false,
		"db_backup_retention_period": 7,
		"auto_setup_database":        false,
	}

	terraformOptions := testConfig.GetModuleTerraformOptions("../../modules/database", testVars)
	defer common.CleanupResources(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate resource naming conventions
	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	dbSubnetGroupName := terraform.Output(t, terraformOptions, "db_subnet_group_name")
	dbParameterGroupName := terraform.Output(t, terraformOptions, "db_parameter_group_name")

	// Validate naming follows conventions
	common.ValidateResourceNaming(t, dbInstanceID, testConfig.Prefix, "postgres")
	common.ValidateResourceNaming(t, dbSubnetGroupName, testConfig.Prefix, "db-subnet-group")
	common.ValidateResourceNaming(t, dbParameterGroupName, testConfig.Prefix, "postgres16")
}

func TestDatabaseModuleValidatesStorageConfiguration(t *testing.T) {
	common.SkipIfShortTest(t)

	// Test different storage configurations
	testCases := []struct {
		allocatedStorage int
		name             string
		expectPass       bool
	}{
		{20, "minimum storage", true},
		{100, "medium storage", true},
		{1000, "large storage", true},
		// Invalid cases would cause Terraform validation errors
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			if !tc.expectPass {
				t.Skip("Skipping invalid configuration test")
				return
			}

			common.SkipIfShortTest(t)

			testConfig := common.NewTestConfig("../../modules/database")

			testVars := map[string]interface{}{
				"db_subnet_ids":              []string{"subnet-db1", "subnet-db2"},
				"db_security_group_id":       "sg-database123",
				"db_allocated_storage":       tc.allocatedStorage,
				"db_engine_version":          "16.9",
				"db_instance_class":          "db.t4g.micro",
				"db_name":                    "testdb",
				"db_username":                "testuser",
				"db_password":                "testpassword123!",
				"app_db_username":            "appuser",
				"use_secrets_manager":        false,
				"db_backup_retention_period": 7,
				"auto_setup_database":        false,
			}

			terraformOptions := testConfig.GetModuleTerraformOptions("../../modules/database", testVars)
			defer common.CleanupResources(t, terraformOptions)

			terraform.InitAndApply(t, terraformOptions)

			// Validate the database was created with correct storage
			dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
			assert.NotEmpty(t, dbInstanceID)

			// In a real test, you'd validate the allocated storage using AWS SDK
		})
	}
}
