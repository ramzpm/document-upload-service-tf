# =============================================================================
# DYNAMODB DATABASE CONFIGURATION
# =============================================================================

# Main file tracking table
resource "aws_dynamodb_table" "file_tracking" {
  name         = local.dynamodb_tables.file_tracking
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "fileId"

  # Primary key attribute
  attribute {
    name = "fileId"
    type = "S"
  }

  # Secondary attributes for indexing
  attribute {
    name = "filename"
    type = "S"
  }

  attribute {
    name = "uploadedStatus"
    type = "S"
  }

  attribute {
    name = "uploadedBy"
    type = "S"
  }

  # Global Secondary Indexes for efficient querying
  global_secondary_index {
    name            = "filename-index"
    hash_key        = "filename"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "uploaded-status-index"
    hash_key        = "uploadedStatus"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "uploaded-by-index"
    hash_key        = "uploadedBy"
    projection_type = "ALL"
  }

  # Point-in-time recovery for production
  point_in_time_recovery {
    enabled = var.environment == "production"
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = "file-tracking-table"
  })
}
