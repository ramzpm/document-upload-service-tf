# =============================================================================
# VARIABLES
# =============================================================================

# AWS Configuration
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
  default     = "file-security-system"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

# S3 Configuration
variable "s3_bucket_name" {
  description = "Name of the main S3 bucket for file uploads"
  type        = string
  default     = "file-upload-bucket-122333"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.s3_bucket_name))
    error_message = "S3 bucket name must be valid (lowercase, numbers, hyphens, dots)."
  }
}

# DynamoDB Configuration
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for file tracking"
  type        = string
  default     = "file-tracking-table"
}

# Lambda Configuration
variable "lambda_runtime" {
  description = "Python runtime version for Lambda functions"
  type        = string
  default     = "python3.12"
  validation {
    condition     = contains(["python3.9", "python3.10", "python3.11", "python3.12"], var.lambda_runtime)
    error_message = "Lambda runtime must be a supported Python version."
  }
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 30
  validation {
    condition     = var.lambda_timeout >= 3 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 3 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda functions in MB"
  type        = number
  default     = 128
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size must be between 128 and 10240 MB."
  }
}

# File Upload Configuration
variable "allowed_file_extensions" {
  description = "List of allowed file extensions for uploads"
  type        = list(string)
  default     = [".txt", ".pdf", ".doc", ".docx", ".jpg", ".png", ".gif"]
}

variable "max_file_size_mb" {
  description = "Maximum file size allowed for uploads in MB"
  type        = number
  default     = 100
  validation {
    condition     = var.max_file_size_mb > 0 && var.max_file_size_mb <= 5000
    error_message = "Max file size must be between 1 and 5000 MB."
  }
}

# Security Configuration
variable "enable_encryption" {
  description = "Enable server-side encryption for S3 buckets"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for Lambda functions"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3653
    error_message = "Log retention must be between 1 and 3653 days."
  }
}

# Monitoring Configuration
variable "SES_RECIPIENT_EMAIL" {
  description = "Receipt mail when the malicious file moved"
  type        = string
  default     = "rameshkumar2217@gmail.com"
}


# Monitoring Configuration
variable "SES_SENDER_EMAIL" {
  description = "Receipt mail when the malicious file moved"
  type        = string
  default     = "rameshkumar.pm@outlook.com"
}


# Amplify Configuration
variable "access_token" {
  description = "GitHub Personal Access Token with repo access"
  type        = string
  sensitive   = true
  default     = ""
}
