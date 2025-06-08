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

1. **Dynamic Parameters**: Parameters that can be changed immediately are defined in the `aws_db_parameter_group.postgres` resource (named `{prefix}-pg-{version}`) and associated with the RDS instance.

2. **Static Parameters**: Parameters that require a restart (such as `shared_preload_libraries`) are defined in a separate `aws_db_parameter_group.postgres_static` resource (named `{prefix}-pg-{version}-static`) with `apply_method = "pending-reboot"`.

### Important Note on Static Parameters

The static parameters are defined in a separate parameter group for documentation and tracking purposes, but **are not currently associated with the RDS instance**. This is because:

1. AWS doesn't allow modifying static parameters with the immediate apply method
2. Changing a parameter group on a running instance can cause issues

To apply these static parameters:

1. Note the values defined in the `postgres_static` parameter group
2. Manually apply them in the AWS console with apply method "pending-reboot"
3. Schedule a restart during a maintenance window

Without these steps, static parameter changes will not take effect.

We've separated the parameters this way to ensure Terraform can successfully apply without errors while still documenting the intended static parameter configuration.

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

| Name                       | Description                                              | Type         | Default        |
| -------------------------- | -------------------------------------------------------- | ------------ | -------------- |
| prefix                     | Prefix to use for resource names                         | string       | "coalition"    |
| db_subnet_ids              | List of subnet IDs for the DB subnet group               | list(string) |                |
| db_security_group_id       | ID of the security group for the database                | string       |                |
| db_allocated_storage       | Allocated storage for the database in GB                 | number       | 20             |
| db_engine_version          | Version of PostgreSQL to use                             | string       | "16.9"         |
| db_instance_class          | Instance class for the database                          | string       | "db.t4g.micro" |
| db_name                    | Name of the database                                     | string       |                |
| db_username                | Master username for the database                         | string       |                |
| db_password                | Master password for the database                         | string       |                |
| app_db_username            | Application database username with restricted privileges | string       |                |
| use_secrets_manager        | Whether to use Secrets Manager for database passwords    | bool         | false          |
| db_backup_retention_period | Backup retention period in days                          | number       | 14             |

## Outputs

| Name                        | Description                                                                   |
| --------------------------- | ----------------------------------------------------------------------------- |
| db_instance_endpoint        | The connection endpoint for the database                                      |
| db_instance_address         | The hostname of the database instance                                         |
| db_instance_port            | The port on which the database accepts connections                            |
| db_name                     | The name of the database                                                      |
| master_username             | The master username for the database                                          |
| app_database_url_secret_arn | The ARN of the Secrets Manager secret containing the application database URL |
