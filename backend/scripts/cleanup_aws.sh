#!/bin/bash
# This script deletes the AWS resources that are causing Terraform conflicts.
# CAUTION: Only use this in development environments as it will delete resources!

set -e

# Function to log messages with timestamps
log() {
  local level=$1
  shift
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
}

# Function for error logging
error() {
  log "ERROR" "$@" >&2
}

# Function for info logging
info() {
  log "INFO" "$@"
}

# Check for AWS CLI
if ! command -v aws &>/dev/null; then
  error "AWS CLI is not installed or not in PATH"
  exit 1
fi

# Configuration
PREFIX="landandbay"
REGION="us-east-1"

info "Starting cleanup of problematic resources for prefix: $PREFIX"

# Verify AWS credentials
info "Verifying AWS credentials..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  error "AWS credentials not configured or invalid"
  error "Please ensure AWS credentials are properly set up"
  exit 1
fi
info "AWS credentials verified successfully"

info "=== STEP 1: Deleting Load Balancer and Target Group ==="
# Remove WAF association first (needs to be done before LB deletion)
info "Checking for WAF associations..."
LB_ARN=$(aws elbv2 describe-load-balancers --names "${PREFIX}-alb" --region "$REGION" 2>/dev/null | jq -r '.LoadBalancers[0].LoadBalancerArn' 2>/dev/null || echo "")
if [ -n "$LB_ARN" ]; then
  info "Removing WAF association from load balancer..."
  aws wafv2 list-resources-for-web-acl --scope REGIONAL --resource-type APPLICATION_LOAD_BALANCER --region "$REGION" 2>/dev/null |
    jq -r '.ResourceArns[] | select(. == "'"$LB_ARN"'")' |
    xargs -r -I{} aws wafv2 disassociate-web-acl --resource-arn {} --region "$REGION" || true

  # Delete listeners
  info "Deleting load balancer listeners..."
  aws elbv2 describe-listeners --load-balancer-arn "$LB_ARN" --region "$REGION" 2>/dev/null |
    jq -r '.Listeners[].ListenerArn' 2>/dev/null |
    xargs -r -I{} aws elbv2 delete-listener --listener-arn {} --region "$REGION" || true

  # Delete load balancer
  info "Deleting load balancer: ${PREFIX}-alb"
  aws elbv2 delete-load-balancer --load-balancer-arn "$LB_ARN" --region "$REGION" || true

  # Wait for load balancer to be deleted
  info "Waiting for load balancer to be fully deleted..."
  sleep 20
else
  info "No load balancer found to delete"
fi

# Delete target group
info "Checking for target group..."
TG_ARN=$(aws elbv2 describe-target-groups --names "${PREFIX}-tg" --region "$REGION" 2>/dev/null | jq -r '.TargetGroups[0].TargetGroupArn' 2>/dev/null || echo "")
if [ -n "$TG_ARN" ]; then
  info "Deleting target group: ${PREFIX}-tg"
  aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$REGION" || true
else
  info "No target group found to delete"
fi

info "=== STEP 2: Cleaning up IAM Roles ==="
# These roles often cause conflicts because they use standard names

# Check for and delete role policies first
IAM_ROLES=("ecsTaskExecutionRole" "ecsTaskRole" "vpc-flow-log-role")

for ROLE in "${IAM_ROLES[@]}"; do
  info "Checking for IAM role: $ROLE"
  if aws iam get-role --role-name "$ROLE" &>/dev/null; then
    # List and delete attached policies
    info "Listing attached policies for $ROLE..."
    ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE" | jq -r '.AttachedPolicies[].PolicyArn')
    for POLICY_ARN in $ATTACHED_POLICIES; do
      info "Detaching policy $POLICY_ARN from role $ROLE"
      aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$POLICY_ARN" || true
    done

    # List and delete inline policies
    info "Listing inline policies for $ROLE..."
    INLINE_POLICIES=$(aws iam list-role-policies --role-name "$ROLE" | jq -r '.PolicyNames[]')
    for POLICY_NAME in $INLINE_POLICIES; do
      info "Deleting inline policy $POLICY_NAME from role $ROLE"
      aws iam delete-role-policy --role-name "$ROLE" --policy-name "$POLICY_NAME" || true
    done

    # Delete the role itself
    info "Deleting IAM role: $ROLE"
    aws iam delete-role --role-name "$ROLE" || true
  else
    info "IAM role $ROLE not found, skipping"
  fi
done

# Delete custom policies
POLICIES=("SecretsManagerAccess" "ecsTaskPolicy" "vpc-flow-log-policy")
for POLICY in "${POLICIES[@]}"; do
  info "Checking for IAM policy: $POLICY"
  POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$POLICY'].Arn" --output text)
  if [ -n "$POLICY_ARN" ] && [ "$POLICY_ARN" != "None" ]; then
    info "Deleting IAM policy: $POLICY_ARN"
    aws iam delete-policy --policy-arn "$POLICY_ARN" || true
  else
    info "IAM policy $POLICY not found, skipping"
  fi
done

info "=== STEP 3: Deleting KMS Aliases ==="
# KMS aliases often cause conflicts because they can't be recreated easily

# Function to delete a KMS alias if it exists
delete_kms_alias() {
  local alias_name="alias/$1"
  info "Checking for KMS alias: $alias_name"

  # Check if alias exists
  if aws kms list-aliases --region "$REGION" | jq -r '.Aliases[].AliasName' | grep -q "^$alias_name$"; then
    info "Deleting KMS alias: $alias_name"

    # Get the target key ID
    TARGET_KEY_ID=$(aws kms list-aliases --region "$REGION" |
      jq -r '.Aliases[] | select(.AliasName=="'"$alias_name"'") | .TargetKeyId')

    if [ -n "$TARGET_KEY_ID" ]; then
      # Delete the alias
      aws kms delete-alias --alias-name "$alias_name" --region "$REGION" || true

      # Schedule key for deletion
      KEY_STATE=$(aws kms describe-key --key-id "$TARGET_KEY_ID" --region "$REGION" | jq -r '.KeyMetadata.KeyState')
      if [ "$KEY_STATE" != "PendingDeletion" ]; then
        info "Scheduling KMS key $TARGET_KEY_ID for deletion"
        aws kms schedule-key-deletion --key-id "$TARGET_KEY_ID" --pending-window-in-days 7 --region "$REGION" || true
      else
        info "KMS key $TARGET_KEY_ID already pending deletion"
      fi
    fi
  else
    info "KMS alias $alias_name not found, skipping"
  fi
}

# Delete specific KMS aliases that are causing issues
delete_kms_alias "${PREFIX}-rds"
delete_kms_alias "${PREFIX}-secrets"

info "=== STEP 4: Deleting RDS Parameter Group ==="
# Delete the RDS Parameter Group that's causing issues

PG_NAME="${PREFIX}-pg16"
info "Checking for RDS parameter group: $PG_NAME"
if aws rds describe-db-parameter-groups --db-parameter-group-name "$PG_NAME" --region "$REGION" &>/dev/null; then
  info "Deleting RDS parameter group: $PG_NAME"
  aws rds delete-db-parameter-group --db-parameter-group-name "$PG_NAME" --region "$REGION" || true
else
  info "RDS parameter group $PG_NAME not found, skipping"
fi

info "=== STEP 5: Deleting DB Subnet Group ==="
# Delete the DB Subnet Group that's causing issues

SUBNET_GROUP_NAME="${PREFIX}-db-subnet"
info "Checking for DB subnet group: $SUBNET_GROUP_NAME"
if aws rds describe-db-subnet-groups --db-subnet-group-name "$SUBNET_GROUP_NAME" --region "$REGION" &>/dev/null; then
  info "Deleting DB subnet group: $SUBNET_GROUP_NAME"
  aws rds delete-db-subnet-group --db-subnet-group-name "$SUBNET_GROUP_NAME" --region "$REGION" || true
else
  info "DB subnet group $SUBNET_GROUP_NAME not found, skipping"
fi

info "=== STEP 6: Deleting Secrets ==="
# Secrets Manager secrets that may cause conflicts

SECRETS=(
  "${PREFIX}/database-master"
  "${PREFIX}/database-url"
  "${PREFIX}/secret-key"
)

for SECRET in "${SECRETS[@]}"; do
  info "Checking for secret: $SECRET"
  if aws secretsmanager describe-secret --secret-id "$SECRET" --region "$REGION" &>/dev/null; then
    info "Deleting secret: $SECRET"
    aws secretsmanager delete-secret --secret-id "$SECRET" --force-delete-without-recovery --region "$REGION" || true
  else
    info "Secret $SECRET not found, skipping"
  fi
done

info "=== STEP 7: Deleting WAF Web ACL ==="
# WAF Web ACLs require special handling with lock tokens

info "Checking for WAF Web ACL: ${PREFIX}-waf"
WAF_ID=$(aws wafv2 list-web-acls --scope REGIONAL --region "$REGION" 2>/dev/null |
  jq -r '.WebACLs[] | select(.Name=="'${PREFIX}'-waf") | .Id' 2>/dev/null || echo "")

if [ -n "$WAF_ID" ]; then
  # Get the lock token
  info "Getting lock token for WAF Web ACL: ${PREFIX}-waf"
  LOCK_TOKEN=$(aws wafv2 get-web-acl --name "${PREFIX}-waf" --scope REGIONAL --id "$WAF_ID" --region "$REGION" |
    jq -r '.LockToken' 2>/dev/null || echo "")

  if [ -n "$LOCK_TOKEN" ]; then
    info "Deleting WAF Web ACL: ${PREFIX}-waf"
    aws wafv2 delete-web-acl --name "${PREFIX}-waf" --scope REGIONAL --id "$WAF_ID" --lock-token "$LOCK_TOKEN" --region "$REGION" || true
  else
    info "Could not get lock token for WAF Web ACL - skipping"
  fi
else
  info "WAF Web ACL not found, skipping"
fi

info "=== STEP 8: Deleting S3 Bucket for ALB Logs ==="
# S3 bucket for ALB logs

BUCKET_NAME="${PREFIX}-alb-logs"
info "Checking for S3 bucket: $BUCKET_NAME"
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
  info "Emptying S3 bucket: $BUCKET_NAME"
  aws s3 rm "s3://$BUCKET_NAME" --recursive || true

  info "Deleting S3 bucket: $BUCKET_NAME"
  aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION" || true
else
  info "S3 bucket $BUCKET_NAME not found, skipping"
fi

info "=== STEP 9: Deleting CloudWatch Log Groups ==="
# CloudWatch log groups

LOG_GROUPS=(
  "/ecs/${PREFIX}"
  "/vpc/flow-logs"
)

for LOG_GROUP in "${LOG_GROUPS[@]}"; do
  info "Checking for log group: $LOG_GROUP"
  if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region "$REGION" | jq -r '.logGroups[].logGroupName' | grep -q "^$LOG_GROUP"; then
    info "Deleting log group: $LOG_GROUP"
    aws logs delete-log-group --log-group-name "$LOG_GROUP" --region "$REGION" || true
  else
    info "Log group $LOG_GROUP not found, skipping"
  fi
done

info "=== STEP 10: Deleting AWS Budget ==="
# AWS Budget

BUDGET_NAME="${PREFIX}-monthly-budget"
info "Checking for budget: $BUDGET_NAME"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if aws budgets describe-budgets --account-id "$ACCOUNT_ID" --region "$REGION" 2>/dev/null | jq -r '.Budgets[].BudgetName' | grep -q "^$BUDGET_NAME$"; then
  info "Deleting budget: $BUDGET_NAME"
  aws budgets delete-budget --account-id "$ACCOUNT_ID" --budget-name "$BUDGET_NAME" --region "$REGION" || true
else
  info "Budget $BUDGET_NAME not found, skipping"
fi

info "Cleanup completed. Problematic resources have been deleted."
info "You can now try running the Terraform apply again."
