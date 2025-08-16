# =============================================================================
# IAM ROLES AND POLICIES
# =============================================================================

# =============================================================================
# LAMBDA EXECUTION ROLES
# =============================================================================

# IAM Role for Presign URL Lambda
resource "aws_iam_role" "presign_lambda" {
  name = "${local.name_prefix}-presign-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "presign-lambda-role"
  })
}

# IAM Role for File Processor Lambda
resource "aws_iam_role" "file_processor_lambda" {
  name = "${local.name_prefix}-file-processor-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "file-processor-lambda-role"
  })
}


# IAM Role for File Fetcher Lambda
resource "aws_iam_role" "file_fetcher_lambda" {
  name = "${local.name_prefix}-file-fetcher-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(local.common_tags, {
    Name = "file-fetcher-lambda-role"
  })
}
# =============================================================================
# BASIC EXECUTION POLICIES
# =============================================================================

# Basic execution role for Presign Lambda
resource "aws_iam_role_policy_attachment" "presign_lambda_basic" {
  role       = aws_iam_role.presign_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Basic execution role for File Processor Lambda
resource "aws_iam_role_policy_attachment" "file_processor_lambda_basic" {
  role       = aws_iam_role.file_processor_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Basic execution role for File Fetcher Lambda
resource "aws_iam_role_policy_attachment" "file_fetcher_lambda_basic" {
  role       = aws_iam_role.file_fetcher_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# =============================================================================
# S3 ACCESS POLICIES
# =============================================================================

# S3 access policy for Presign Lambda
resource "aws_iam_role_policy" "presign_s3_access" {
  name = "${local.name_prefix}-presign-s3-access"
  role = aws_iam_role.presign_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      }
    ]
  })
}

# S3 access policy for File Processor Lambda
resource "aws_iam_role_policy" "file_processor_s3_access" {
  name = "${local.name_prefix}-file-processor-s3-access"
  role = aws_iam_role.file_processor_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectTagging"
        ]
        Resource = [
          "${aws_s3_bucket.uploads.arn}/*",
          "${aws_s3_bucket.malware.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.uploads.arn,
          aws_s3_bucket.malware.arn
        ]
      }
    ]
  })
}

# =============================================================================
# DYNAMODB ACCESS POLICIES
# =============================================================================

# DynamoDB access policy for File Processor Lambda
resource "aws_iam_role_policy" "file_processor_dynamodb_access" {
  name = "${local.name_prefix}-file-processor-dynamodb-access"
  role = aws_iam_role.file_processor_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.file_tracking.arn,
          "${aws_dynamodb_table.file_tracking.arn}/index/*"
        ]
      }
    ]
  })
}


# DynamoDB access policy for File Processor Lambda
resource "aws_iam_role_policy" "file_fetcher_dynamodb_access" {
  name = "${local.name_prefix}-file_fetcher_dynamodb_access"
  role = aws_iam_role.file_fetcher_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.file_tracking.arn,
          "${aws_dynamodb_table.file_tracking.arn}/index/*"
        ]
      }
    ]
  })
}


# IAM policy for Lambda to send emails using SES
resource "aws_iam_role_policy" "file_processor_ses_access" {
  name = "${local.name_prefix}-file-processor-ses-access"
  role = aws_iam_role.file_processor_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

