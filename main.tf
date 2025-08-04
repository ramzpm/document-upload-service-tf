# =============================================================================
# MAIN CONFIGURATION
# =============================================================================
# This file serves as the main entry point and orchestrates all components

# Data sources for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values for common tags and naming
locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Purpose     = "file-upload-security"
    Version     = "1.0.0"
  }

  # Resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"

  # Lambda function names
  lambda_functions = {
    presign_url    = "${local.name_prefix}-presign-url"
    file_processor = "${local.name_prefix}-file-processor"
  }

  # S3 bucket names
  s3_buckets = {
    uploads = var.s3_bucket_name
    malware = "${var.s3_bucket_name}-malware-objects"
  }

  # DynamoDB table names
  dynamodb_tables = {
    file_tracking = var.dynamodb_table_name
  }
}
