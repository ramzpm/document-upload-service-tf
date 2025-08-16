# =============================================================================
# OUTPUTS
# =============================================================================

# =============================================================================
# API GATEWAY OUTPUTS
# =============================================================================

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_apigatewayv2_api.file_upload_api.id
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.file_upload_api.api_endpoint
}

output "presign_url_endpoint" {
  description = "Full URL for presign URL generation"
  value       = "${aws_apigatewayv2_api.file_upload_api.api_endpoint}/presign"
}

# =============================================================================
# LAMBDA FUNCTION OUTPUTS
# =============================================================================

output "presign_lambda_name" {
  description = "Name of the presign URL Lambda function"
  value       = aws_lambda_function.presign_url.function_name
}

output "presign_lambda_arn" {
  description = "ARN of the presign URL Lambda function"
  value       = aws_lambda_function.presign_url.arn
}

output "file_processor_lambda_name" {
  description = "Name of the file processor Lambda function"
  value       = aws_lambda_function.file_processor.function_name
}

output "file_processor_lambda_arn" {
  description = "ARN of the file processor Lambda function"
  value       = aws_lambda_function.file_processor.arn
}

# =============================================================================
# S3 BUCKET OUTPUTS
# =============================================================================

output "upload_bucket_name" {
  description = "Name of the S3 bucket for file uploads"
  value       = aws_s3_bucket.uploads.bucket
}

output "upload_bucket_arn" {
  description = "ARN of the S3 bucket for file uploads"
  value       = aws_s3_bucket.uploads.arn
}

output "malware_bucket_name" {
  description = "Name of the S3 bucket for malware objects"
  value       = aws_s3_bucket.malware.bucket
}

output "malware_bucket_arn" {
  description = "ARN of the S3 bucket for malware objects"
  value       = aws_s3_bucket.malware.arn
}

# =============================================================================
# DYNAMODB OUTPUTS
# =============================================================================

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for file tracking"
  value       = aws_dynamodb_table.file_tracking.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for file tracking"
  value       = aws_dynamodb_table.file_tracking.arn
}

# =============================================================================
# AWS ACCOUNT AND REGION OUTPUTS
# =============================================================================

output "aws_account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "Current AWS region"
  value       = data.aws_region.current.name
}

# =============================================================================
# SYSTEM INFORMATION OUTPUTS
# =============================================================================

output "project_name" {
  description = "Name of the project"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "system_version" {
  description = "Version of the file security system"
  value       = "1.0.0"
}



# =============================================================================
# Front end INFORMATION OUTPUTS
# =============================================================================


