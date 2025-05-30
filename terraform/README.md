# Terraform Infrastructure for Land and Bay Stewards

This directory contains the Terraform configuration for deploying the Land and Bay Stewards application to AWS. The infrastructure is designed to be secure, scalable, and SOC 2 compliant.

## Security Features

The infrastructure includes the following security features:

- **AWS Secrets Manager** for secure credential storage
- **Secure credential generation** for database users
- **IAM roles with least privilege** for all services
- **KMS encryption** for sensitive data
- **VPC security groups** with restricted access
- **Network isolation** for database resources
- **Application-level separation of privileges**

## Secure Credentials Management

### Database Credentials

Database credentials are managed securely through AWS Secrets Manager:

1. **Master Database User**: Administrative user with full database privileges
   - Credentials stored in AWS Secrets Manager
   - Used only for initial setup and maintenance
   - Not exposed to application code

2. **Application Database User**: Restricted user for application access
   - Automatically generated secure password
   - Limited privileges based on principle of least privilege
   - Credentials injected into application via Secrets Manager

### Credential Lifecycle

1. **Initial Setup**:
   - If secrets don't exist, they are created with secure passwords
   - If secrets exist, they are used for deployment

2. **Manual Password Updates**:
   - Passwords can be updated manually through AWS Secrets Manager console
   - No need to update Terraform configuration

3. **Future Enhancement**:
   - Automated password rotation is not currently configured
   - May be implemented in future releases using AWS Lambda and Secrets Manager rotation schedules

4. **Access Control**:
   - IAM policies restrict access to secrets
   - KMS encryption adds another layer of security
   - Audit logging tracks all access to secrets

## Using Secrets Manager

### For Initial Deployment

For the initial deployment, you have two options:

1. **Pre-create secrets** (recommended for production):

   ```bash
   # Create master credentials secret
   aws secretsmanager create-secret \
     --name landandbay/database-master \
     --description "PostgreSQL master database credentials" \
     --secret-string '{"username":"your_secure_username","password":"your_secure_password"}'
   
   # Optional: Create application credentials secret
   aws secretsmanager create-secret \
     --name landandbay/database-app \
     --description "PostgreSQL application database credentials" \
     --secret-string '{"username":"app_user","password":"your_secure_app_password"}'
   ```

2. **Let Terraform create secrets** (development/testing only):
   - Set `TF_VAR_use_secrets_manager=true`
   - Provide initial values for `TF_VAR_db_username` and `TF_VAR_db_password` for first run only
   - Terraform creates secrets with secure passwords for application database

### Accessing Secrets

To view the secrets:

```bash
# View master credentials
aws secretsmanager get-secret-value --secret-id landandbay/database-master --query SecretString --output text | jq .

# View application credentials
aws secretsmanager get-secret-value --secret-id landandbay/database-app --query SecretString --output text | jq .
```

## Variables

| Variable Name | Description | Default | Required |
|---------------|-------------|---------|----------|
| `use_secrets_manager` | Enable AWS Secrets Manager integration | `true` | No |
| `db_username` | Master database username (used only for initial setup) | `postgres_admin` | No |
| `db_password` | Master database password (used only for initial setup) | n/a | Yes, for initial setup only |
| `app_db_username` | Application database username | `app_user` | No |
| `app_db_password` | Application database password (auto-generated if not provided) | n/a | No |

## Best Practices

1. **Never hardcode credentials** in Terraform files or environment variables
2. **Use Secrets Manager** for all production deployments
3. **Update credentials** manually through AWS Secrets Manager when needed
4. **Limit access** to the secrets using IAM policies
5. **Monitor access** to secrets through CloudTrail
6. **Use encrypted communications** for all database connections