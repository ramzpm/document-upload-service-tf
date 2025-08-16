# =============================================================================
# S3 STORAGE CONFIGURATION
# =============================================================================

# Main upload bucket for incoming files
resource "aws_s3_bucket" "uploads" {
  bucket        = local.s3_buckets.uploads
  force_destroy = var.environment != "production"

  tags = merge(local.common_tags, {
    Name = "file-uploads"
  })
}

# Malware quarantine bucket for malicious files
resource "aws_s3_bucket" "malware" {
  bucket        = local.s3_buckets.malware
  force_destroy = var.environment != "production"

  tags = merge(local.common_tags, {
    Name = "malware-quarantine"
  })
}

# =============================================================================
# S3 BUCKET CONFIGURATIONS
# =============================================================================

# Versioning for upload bucket
resource "aws_s3_bucket_versioning" "uploads" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Versioning for malware bucket
resource "aws_s3_bucket_versioning" "malware" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.malware.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for upload bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Server-side encryption for malware bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "malware" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.malware.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access block for upload bucket
resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Public access block for malware bucket
resource "aws_s3_bucket_public_access_block" "malware" {
  bucket = aws_s3_bucket.malware.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_cors_configuration" "file_upload_cors" {
  bucket = aws_s3_bucket.uploads.id
  cors_rule {
    id = "CORSRule1"

    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    allowed_origins = ["*"] # 👈 You can restrict this later to your Amplify domain
    expose_headers  = ["ETag"]

    max_age_seconds = 3000
  }
}
