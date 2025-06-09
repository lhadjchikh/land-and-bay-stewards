#!/bin/bash
# Database Setup Script for Coalition Builder
# This script sets up PostgreSQL with PostGIS and creates application user
# Run this after Terraform has created the RDS instance

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Default configuration
DEFAULT_PREFIX="coalition"
DEFAULT_DB_NAME="coalition"
DEFAULT_MASTER_USERNAME="postgres_admin"
DEFAULT_APP_USERNAME="app_user"
DEFAULT_REGION="us-east-1"

# Function to show usage
usage() {
  cat <<EOF
Database Setup Script for Coalition Builder

Usage: $0 [OPTIONS]

OPTIONS:
    -e, --endpoint ENDPOINT     Database endpoint (required)
    -d, --database DATABASE     Database name (default: $DEFAULT_DB_NAME)
    -u, --master-user USER      Master username (default: $DEFAULT_MASTER_USERNAME)
    -a, --app-user USER         Application username (default: $DEFAULT_APP_USERNAME)
    -p, --prefix PREFIX         Resource prefix for secrets (default: $DEFAULT_PREFIX)
    -r, --region REGION         AWS region (default: $DEFAULT_REGION)
    -h, --help                  Show this help message

EXAMPLES:
    # Basic usage with Terraform output
    $0 --endpoint \$(terraform output -raw database_endpoint)
    
    # Custom configuration
    $0 --endpoint mydb.abc123.us-east-1.rds.amazonaws.com --database myapp --prefix myapp
    
    # Get database endpoint from Terraform
    DB_ENDPOINT=\$(terraform output -raw database_endpoint)
    $0 --endpoint "\$DB_ENDPOINT"

NOTES:
    - You will be prompted for the master database password
    - The script generates a secure random password for the application user
    - Both passwords are stored in AWS Secrets Manager
    - PostGIS extension is automatically enabled
    - The application user gets restricted privileges following least privilege principle

EOF
}

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to install PostgreSQL client
install_psql() {
  log_info "Installing PostgreSQL client..."

  if command_exists apt-get; then
    sudo apt-get update && sudo apt-get install -y postgresql-client
  elif command_exists yum; then
    sudo yum install -y postgresql
  elif command_exists dnf; then
    sudo dnf install -y postgresql
  elif command_exists brew; then
    brew install postgresql
  elif command_exists pacman; then
    sudo pacman -S postgresql
  else
    log_error "Cannot automatically install PostgreSQL client."
    log_error "Please install 'psql' manually and run this script again."
    exit 1
  fi
}

# Function to validate prerequisites
check_prerequisites() {
  log_info "Checking prerequisites..."

  # Check PostgreSQL client
  if ! command_exists psql; then
    log_warning "PostgreSQL client (psql) not found"
    read -p "Would you like to install it automatically? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      install_psql
    else
      log_error "PostgreSQL client is required. Please install 'psql' and try again."
      exit 1
    fi
  else
    log_success "PostgreSQL client found"
  fi

  # Check AWS CLI
  if ! command_exists aws; then
    log_error "AWS CLI is not installed or not in PATH"
    log_error "Please install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
  else
    log_success "AWS CLI found"
  fi

  # Check AWS CLI configuration
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    log_error "AWS CLI is not properly configured or lacks permissions"
    log_error "Please run 'aws configure' or check your IAM permissions"
    exit 1
  else
    log_success "AWS CLI properly configured"
  fi

  # Check for required tools
  for tool in openssl python3 sed; do
    if ! command_exists "$tool"; then
      log_error "$tool is required but not found"
      exit 1
    fi
  done

  log_success "All prerequisites met"
}

# Function to wait for database to be ready
wait_for_database() {
  local endpoint="$1"
  local username="$2"
  local password="$3"
  local database="$4"
  local max_attempts=20
  local attempt=1

  log_info "Waiting for database to be ready..."

  while [ $attempt -le $max_attempts ]; do
    log_info "Attempt $attempt/$max_attempts: Testing database connection..."

    if PGPASSWORD="$password" psql -h "$endpoint" -U "$username" -d "$database" -c "SELECT 1;" >/dev/null 2>&1; then
      log_success "Database is ready!"
      return 0
    fi

    if [ $attempt -eq $max_attempts ]; then
      log_error "Database did not become available after $max_attempts attempts"
      return 1
    fi

    log_info "Database not ready yet, waiting 30 seconds..."
    sleep 30
    attempt=$((attempt + 1))
  done
}

# Function to URL encode password safely
url_encode_password() {
  local password="$1"
  local encoded_password

  # Check if Python3 is available
  if ! command -v python3 >/dev/null 2>&1; then
    log_error "Python3 is required for password URL encoding but is not available"
    log_error "Please install Python3 or regenerate password with only alphanumeric characters"
    return 1
  fi

  # Attempt URL encoding with proper error handling
  if ! encoded_password=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$password', safe=''))" 2>/dev/null); then
    log_error "Failed to URL encode password using Python3"
    log_error "This might be due to special characters in the password"
    return 1
  fi

  if [ -z "$encoded_password" ]; then
    log_error "Password encoding resulted in empty string"
    return 1
  fi

  echo "$encoded_password"
}

# Function to check if password needs URL encoding
password_needs_encoding() {
  local password="$1"

  # Check if password contains URL-unsafe characters
  if [[ "$password" =~ [@:/\%\?\#\&[:space:]] ]]; then
    return 0 # True - needs encoding
  else
    return 1 # False - safe to use raw
  fi
}

# Function to generate URL-safe password
generate_password() {
  log_info "Generating URL-safe password..."

  # Generate password with only URL-safe characters
  # Avoid: @, :, /, %, ?, #, &, space and other problematic chars
  local safe_password
  safe_password=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9._~-' | head -c 32)

  if [ ${#safe_password} -lt 16 ]; then
    log_error "Generated password is too short"
    return 1
  fi

  echo "$safe_password"
}

# Function to execute database setup
setup_database() {
  local endpoint="$1"
  local database="$2"
  local master_username="$3"
  local master_password="$4"
  local app_username="$5"
  local app_password="$6"

  log_info "Setting up database extensions and user..."

  # METHOD 1: Direct execution with PostgreSQL variables (MOST SECURE)
  log_info "Using PostgreSQL variables for secure execution..."

  if PGPASSWORD="$master_password" psql -h "$endpoint" -U "$master_username" -d "$database" \
    -v app_user="$app_username" \
    -v app_pass="$app_password" \
    -v db_name="$database" \
    <<'EOF'; then
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create or update application user with the generated password
DO $
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = :'app_user') THEN
        -- Create the user if it doesn't exist
        EXECUTE format('CREATE USER %I WITH PASSWORD %L', :'app_user', :'app_pass');
        RAISE NOTICE 'Created user: %', :'app_user';
    ELSE
        -- Update the password if user already exists
        EXECUTE format('ALTER USER %I WITH PASSWORD %L', :'app_user', :'app_pass');
        RAISE NOTICE 'Updated password for user: %', :'app_user';
    END IF;
END
$;

-- Grant comprehensive privileges for Django application
DO $
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', :'db_name', :'app_user');
    EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', :'app_user');
    EXECUTE format('GRANT CREATE ON SCHEMA public TO %I', :'app_user');
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO %I', :'app_user');
    EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO %I', :'app_user');
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO %I', :'app_user');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I', :'app_user');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO %I', :'app_user');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO %I', :'app_user');
END
$;

-- Show confirmation
SELECT 'Database setup completed successfully!' as status;
EOF
    log_success "Database setup completed using PostgreSQL variables"
    return 0
  fi

  # FALLBACK: File-based approach with safe substitution
  log_warning "Direct execution failed, falling back to file-based approach with safe substitution"

  local sql_file
  if ! sql_file=$(mktemp /tmp/db_setup_XXXXXX.sql); then
    log_error "Failed to create temporary SQL file"
    return 1
  fi

  # Create SQL using Python for safe string handling
  if command_exists python3; then
    log_info "Using Python for safe SQL generation..."
    python3 <<PYEOF >"$sql_file"
import sys

app_username = """$app_username"""
app_password = """$app_password"""
database = """$database"""

# Use triple quotes and proper escaping
sql_content = f'''-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create or update application user with the generated password
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '{app_username}') THEN
        -- Create the user if it doesn't exist (using format for safety)
        EXECUTE format('CREATE USER %I WITH PASSWORD %L', '{app_username}', '{app_password}');
        RAISE NOTICE 'Created user: {app_username}';
    ELSE
        -- Update the password if user already exists
        EXECUTE format('ALTER USER %I WITH PASSWORD %L', '{app_username}', '{app_password}');
        RAISE NOTICE 'Updated password for user: {app_username}';
    END IF;
END
\$\$;

-- Grant privileges using format() for identifier safety
DO \$\$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', '{database}', '{app_username}');
    EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', '{app_username}');
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO %I', '{app_username}');
    EXECUTE format('GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO %I', '{app_username}');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I', '{app_username}');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO %I', '{app_username}');
END
\$\$;

-- Show confirmation
SELECT 'Database setup completed successfully!' as status;'''

print(sql_content)
PYEOF
  else
    # Last resort: Use Perl or safe sed
    log_info "Using template with safe substitution..."
    cat >"$sql_file" <<'EOF'
CREATE EXTENSION IF NOT EXISTS postgis;
DO $
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'PLACEHOLDER_USER') THEN
        EXECUTE format('CREATE USER %I WITH PASSWORD %L', 'PLACEHOLDER_USER', 'PLACEHOLDER_PASSWORD');
    ELSE
        EXECUTE format('ALTER USER %I WITH PASSWORD %L', 'PLACEHOLDER_USER', 'PLACEHOLDER_PASSWORD');
    END IF;
END
$;
DO $
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', 'PLACEHOLDER_DB', 'PLACEHOLDER_USER');
    EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', 'PLACEHOLDER_USER');
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO %I', 'PLACEHOLDER_USER');
    EXECUTE format('GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO %I', 'PLACEHOLDER_USER');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I', 'PLACEHOLDER_USER');
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO %I', 'PLACEHOLDER_USER');
END
$;
EOF

    # Safe substitution using Perl if available
    if command_exists perl; then
      log_info "Using Perl for safe substitution..."
      perl -i -pe "s/PLACEHOLDER_PASSWORD/\Q$app_password\E/g" "$sql_file"
      perl -i -pe "s/PLACEHOLDER_USER/\Q$app_username\E/g" "$sql_file"
      perl -i -pe "s/PLACEHOLDER_DB/\Q$database\E/g" "$sql_file"
    else
      log_info "Using sed with proper escaping..."

      # Escape special characters for sed
      local escaped_password
      if ! escaped_password=$(printf '%s\n' "$app_password" | sed 's/[\/&]/\\&/g'); then
        log_error "Failed to escape password for sed"
        rm -f "$sql_file"
        return 1
      fi

      local escaped_username
      if ! escaped_username=$(printf '%s\n' "$app_username" | sed 's/[\/&]/\\&/g'); then
        log_error "Failed to escape username for sed"
        rm -f "$sql_file"
        return 1
      fi

      local escaped_database
      if ! escaped_database=$(printf '%s\n' "$database" | sed 's/[\/&]/\\&/g'); then
        log_error "Failed to escape database name for sed"
        rm -f "$sql_file"
        return 1
      fi
      # Use | as delimiter instead of / to avoid conflicts
      sed -i "s|PLACEHOLDER_PASSWORD|$escaped_password|g" "$sql_file"
      sed -i "s|PLACEHOLDER_USER|$escaped_username|g" "$sql_file"
      sed -i "s|PLACEHOLDER_DB|$escaped_database|g" "$sql_file"
    fi
  fi

  # Execute the SQL script
  if PGPASSWORD="$master_password" psql -h "$endpoint" -U "$master_username" -d "$database" -f "$sql_file"; then
    log_success "Database setup SQL executed successfully"
    rm -f "$sql_file"
    return 0
  else
    log_error "Failed to execute database setup SQL"
    rm -f "$sql_file"
    return 1
  fi
}

# Function to update secrets manager
update_secrets() {
  local prefix="$1"
  local app_username="$2"
  local app_password="$3"
  local endpoint="$4"
  local database="$5"
  local master_username="$6"
  local master_password="$7"

  log_info "Updating AWS Secrets Manager..."

  # URL encode the password only if needed
  local encoded_password="$app_password" # Default to raw password

  if password_needs_encoding "$app_password"; then
    log_info "Password contains special characters, URL encoding required..."

    if ! encoded_password=$(url_encode_password "$app_password"); then
      log_error "Failed to URL encode password. This will likely cause connection issues."
      log_error "Consider regenerating password with only alphanumeric characters."
      return 1
    fi

    log_success "Password successfully URL encoded"
  else
    log_info "Password is URL-safe, no encoding needed"
  fi

  # Extract host and port from endpoint
  local host="${endpoint%:*}"
  local port="5432"
  if [[ "$endpoint" == *":"* ]]; then
    port="${endpoint##*:}"
  fi

  # Update application database secret
  log_info "Updating application database secret..."
  local app_secret_json

  # Declare and assign separately to avoid masking return values
  app_secret_json=$(
    cat <<EOF
{
    "url": "postgresql://$app_username:$encoded_password@$endpoint/$database",
    "username": "$app_username",
    "password": "$app_password",
    "host": "$host",
    "port": "$port",
    "dbname": "$database"
}
EOF
  )

  if [ -z "$app_secret_json" ]; then
    log_error "Failed to create application secret JSON"
    return 1
  fi

  if aws secretsmanager update-secret \
    --secret-id "$prefix/database-url" \
    --secret-string "$app_secret_json" >/dev/null 2>&1; then
    log_success "Updated application database secret"
  else
    log_error "Failed to update application database secret"
    return 1
  fi

  # Update or create master database secret
  log_info "Updating master database secret..."
  local master_secret_json

  # Declare and assign separately to avoid masking return values
  master_secret_json=$(
    cat <<EOF
{
    "username": "$master_username",
    "password": "$master_password",
    "host": "$host",
    "port": "$port",
    "dbname": "$database"
}
EOF
  )

  if [ -z "$master_secret_json" ]; then
    log_error "Failed to create master secret JSON"
    return 1
  fi

  if aws secretsmanager describe-secret --secret-id "$prefix/database-master" >/dev/null 2>&1; then
    log_info "Updating existing master secret..."
    aws secretsmanager update-secret \
      --secret-id "$prefix/database-master" \
      --secret-string "$master_secret_json" >/dev/null
  else
    log_info "Creating new master secret..."
    aws secretsmanager create-secret \
      --name "$prefix/database-master" \
      --secret-string "$master_secret_json" >/dev/null
  fi

  log_success "Secrets Manager updated successfully"
  return 0
}

# Function to show connection info
show_connection_info() {
  local endpoint="$1"
  local database="$2"
  local app_username="$3"
  local prefix="$4"

  cat <<EOF

${GREEN}=== Database Setup Complete ===${NC}

${BLUE}Application Database Connection:${NC}
  Host: ${endpoint%:*}
  Port: 5432
  Database: $database
  Username: $app_username
  Password: (stored in AWS Secrets Manager: $prefix/database-url)

${BLUE}To retrieve the application password:${NC}
  aws secretsmanager get-secret-value --secret-id "$prefix/database-url" --query SecretString --output text | jq -r .password

${BLUE}For pgAdmin through bastion host:${NC}
  1. Create SSH tunnel: ssh -i /path/to/key.pem ec2-user@<bastion-ip> -L 5432:${endpoint%:*}:5432
  2. Connect to: localhost:5432

${BLUE}Direct connection string (for testing):${NC}
  postgresql://$app_username:<password>@$endpoint/$database

EOF
}

# Main function
main() {
  local endpoint=""
  local database="$DEFAULT_DB_NAME"
  local master_username="$DEFAULT_MASTER_USERNAME"
  local app_username="$DEFAULT_APP_USERNAME"
  local prefix="$DEFAULT_PREFIX"
  local region="$DEFAULT_REGION"

  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -e | --endpoint)
        endpoint="$2"
        shift 2
        ;;
      -d | --database)
        database="$2"
        shift 2
        ;;
      -u | --master-user)
        master_username="$2"
        shift 2
        ;;
      -a | --app-user)
        app_username="$2"
        shift 2
        ;;
      -p | --prefix)
        prefix="$2"
        shift 2
        ;;
      -r | --region)
        region="$2"
        shift 2
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  # Validate required parameters
  if [ -z "$endpoint" ]; then
    log_error "Database endpoint is required"
    echo
    usage
    exit 1
  fi

  # Set AWS region
  export AWS_DEFAULT_REGION="$region"

  # Show configuration
  log_info "Database Setup Configuration:"
  echo "  Endpoint: $endpoint"
  echo "  Database: $database"
  echo "  Master User: $master_username"
  echo "  App User: $app_username"
  echo "  Prefix: $prefix"
  echo "  Region: $region"
  echo

  # Check prerequisites
  check_prerequisites

  # Get master password securely
  echo
  log_info "Enter the master database password:"
  echo -n "Password: "
  read -rs master_password
  echo

  if [ -z "$master_password" ]; then
    log_error "Master password is required"
    exit 1
  fi

  # Wait for database to be ready
  if ! wait_for_database "$endpoint" "$master_username" "$master_password" "$database"; then
    log_error "Database is not accessible. Please check:"
    echo "  - RDS instance is running and available"
    echo "  - Security groups allow connections"
    echo "  - Network connectivity from this machine"
    echo "  - Credentials are correct"
    exit 1
  fi

  # Generate application user password
  log_info "Generating secure password for application user..."
  local app_password
  app_password=$(generate_password)

  if [ -z "$app_password" ]; then
    log_error "Failed to generate application password"
    exit 1
  fi

  log_success "Generated secure password for $app_username"

  # Setup database
  if ! setup_database "$endpoint" "$database" "$master_username" "$master_password" "$app_username" "$app_password"; then
    log_error "Database setup failed"
    exit 1
  fi

  # Update secrets manager
  if ! update_secrets "$prefix" "$app_username" "$app_password" "$endpoint" "$database" "$master_username" "$master_password"; then
    log_error "Failed to update Secrets Manager"
    exit 1
  fi

  # Show connection information
  show_connection_info "$endpoint" "$database" "$app_username" "$prefix"

  # Clean up variables
  unset master_password app_password

  log_success "Database setup completed successfully!"
}

# Run main function with all arguments
main "$@"
