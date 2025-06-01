# Database Module

This module creates and configures an Amazon RDS PostgreSQL database with appropriate parameter groups, security settings, and user management.

## Features

- PostgreSQL database with configurable instance class and storage
- PostGIS extension enabled automatically
- KMS encryption for data at rest
- Application-specific user with restricted privileges
- Secrets Manager integration for credential storage
- Configurable backup retention period
- DB subnet group and security group configuration

## Parameter Group Management

This module uses a split approach for managing database parameters:

1. **Dynamic Parameters**: Parameters that can be changed immediately are defined directly in the `aws_db_parameter_group` resource.

2. **Static Parameters**: Parameters that require a restart (such as `shared_preload_libraries`) are defined in separate `aws_db_parameter_group_parameter` resources with `apply_method = "pending-reboot"`.

### Important Note on Static Parameters

After applying changes to static parameters, you'll need to either:
- Manually restart the RDS instance
- Wait for the next scheduled maintenance window

Without a restart, changes to static parameters will not take effect.

Note that this module allows Terraform to directly manage all parameters, both static and dynamic. The only difference is in how they are applied:
- Dynamic parameters are applied immediately
- Static parameters are applied with the "pending-reboot" method

This ensures that Terraform maintains full control over the parameter values while respecting AWS constraints on parameter modification.

## Usage

```hcl
module "database" {
  source = "./modules/database"

  prefix              = "myapp"
  db_subnet_ids       = module.networking.database_subnet_ids
  db_security_group_id = module.networking.database_security_group_id
  db_name             = "myappdb"
  db_username         = "admin"
  db_password         = "securepassword"
  app_db_username     = "app_user"
  use_secrets_manager = true
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| prefix | Prefix to use for resource names | string | "landandbay" |
| db_subnet_ids | List of subnet IDs for the DB subnet group | list(string) | |
| db_security_group_id | ID of the security group for the database | string | |
| db_allocated_storage | Allocated storage for the database in GB | number | 20 |
| db_engine_version | Version of PostgreSQL to use | string | "16.9" |
| db_instance_class | Instance class for the database | string | "db.t4g.micro" |
| db_name | Name of the database | string | |
| db_username | Master username for the database | string | |
| db_password | Master password for the database | string | |
| app_db_username | Application database username with restricted privileges | string | |
| use_secrets_manager | Whether to use Secrets Manager for database passwords | bool | false |
| db_backup_retention_period | Backup retention period in days | number | 14 |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_endpoint | The connection endpoint for the database |
| db_instance_address | The hostname of the database instance |
| db_instance_port | The port on which the database accepts connections |
| db_name | The name of the database |
| master_username | The master username for the database |
| app_database_url_secret_arn | The ARN of the Secrets Manager secret containing the application database URL |