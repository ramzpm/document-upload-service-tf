# =============================================================================
# LAMBDA FUNCTIONS CONFIGURATION
# =============================================================================

# =============================================================================
# LAMBDA FUNCTION PACKAGING
# =============================================================================

# Package Presign URL Lambda function code
data "archive_file" "presign_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/presign_url.py"
  output_path = "${path.module}/lambda/presign_url.zip"
}

# Package File Processor Lambda function code
data "archive_file" "file_processor_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/file_processor.py"
  output_path = "${path.module}/lambda/file_processor.zip"
}

# =============================================================================
# LAMBDA FUNCTION DEFINITIONS
# =============================================================================

# Presign URL Lambda function
resource "aws_lambda_function" "presign_url" {
  function_name = local.lambda_functions.presign_url
  role          = aws_iam_role.presign_lambda.arn
  handler       = "presign_url.lambda_handler"
  runtime       = var.lambda_runtime
  filename      = data.archive_file.presign_lambda.output_path
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  environment {
    variables = {
      UPLOAD_BUCKET_NAME = aws_s3_bucket.uploads.bucket
      ALLOWED_EXTENSIONS = join(",", var.allowed_file_extensions)
      MAX_FILE_SIZE_MB   = var.max_file_size_mb
    }
  }

  tags = merge(local.common_tags, {
    Name = "presign-url-lambda"
  })
}

# File Processor Lambda function
resource "aws_lambda_function" "file_processor" {
  function_name = local.lambda_functions.file_processor
  role          = aws_iam_role.file_processor_lambda.arn
  handler       = "file_processor.lambda_handler"
  runtime       = var.lambda_runtime
  filename      = data.archive_file.file_processor_lambda.output_path
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.file_tracking.name
      UPLOAD_BUCKET_NAME  = aws_s3_bucket.uploads.bucket
      MALWARE_BUCKET_NAME = aws_s3_bucket.malware.bucket
    }
  }

  tags = merge(local.common_tags, {
    Name = "file-processor-lambda"
  })
}

# =============================================================================
# S3 TRIGGER CONFIGURATION
# =============================================================================

# S3 bucket notification for file processing
resource "aws_s3_bucket_notification" "file_processor" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.file_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_file_processor]
}

# Lambda permission for S3 to invoke file processor
resource "aws_lambda_permission" "s3_file_processor" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}

# =============================================================================
# CLOUDWATCH LOG GROUPS
# =============================================================================

# CloudWatch log group for Presign URL Lambda
resource "aws_cloudwatch_log_group" "presign_url" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  name              = "/aws/lambda/${aws_lambda_function.presign_url.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "presign-url-logs"
  })
}

# CloudWatch log group for File Processor Lambda
resource "aws_cloudwatch_log_group" "file_processor" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  
  name              = "/aws/lambda/${aws_lambda_function.file_processor.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "file-processor-logs"
  })
} 