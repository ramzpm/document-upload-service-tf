# Terraform configuration for S3 File Upload and Malware Scanning System
# This project provides a secure file upload system with automatic malware detection

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "file-upload-security"
    }
  }
}
