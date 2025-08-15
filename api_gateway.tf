# =============================================================================
# API GATEWAY CONFIGURATION
# =============================================================================

# HTTP API Gateway
resource "aws_apigatewayv2_api" "file_upload_api" {
  name          = "${local.name_prefix}-file-upload-api"
  protocol_type = "HTTP"
  description   = "API Gateway for secure file upload system"

  tags = merge(local.common_tags, {
    Name = "file-upload-api"
  })
}

# =============================================================================
# LAMBDA INTEGRATIONS
# =============================================================================

# Lambda integration for Presign URL endpoint
resource "aws_apigatewayv2_integration" "presign_url" {
  api_id                 = aws_apigatewayv2_api.file_upload_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.presign_url.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Lambda integration for File Upload GET by fileId endpoint
resource "aws_apigatewayv2_integration" "file_fetcher" {
  api_id                 = aws_apigatewayv2_api.file_upload_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.file_fetcher.invoke_arn
  payload_format_version = "2.0"
}


# =============================================================================
# API ROUTES
# =============================================================================

# Route for presign URL generation
resource "aws_apigatewayv2_route" "presign_url" {
  api_id    = aws_apigatewayv2_api.file_upload_api.id
  route_key = "GET /presign"
  target    = "integrations/${aws_apigatewayv2_integration.presign_url.id}"
}


# Route for fetching file upload info by fileId
resource "aws_apigatewayv2_route" "file_fetcher" {
  api_id    = aws_apigatewayv2_api.file_upload_api.id
  route_key = "GET /file-upload/{fileId}"
  target    = "integrations/${aws_apigatewayv2_integration.file_fetcher.id}"
}

# =============================================================================
# API STAGE AND DEPLOYMENT
# =============================================================================

# Default stage for API Gateway
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.file_upload_api.id
  name        = "$default"
  auto_deploy = true

  tags = merge(local.common_tags, {
    Name = "api-default-stage"
  })
}

# =============================================================================
# LAMBDA PERMISSIONS
# =============================================================================

# Lambda permission for API Gateway to invoke presign URL function
resource "aws_lambda_permission" "api_presign_url" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presign_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.file_upload_api.execution_arn}/*/*"
}



# Lambda permission for API Gateway to invoke file upload GET function
resource "aws_lambda_permission" "api_file_fetcher" {
  statement_id  = "AllowExecutionFromAPIGatewayFileUploadGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_fetcher.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.file_upload_api.execution_arn}/*/*"
}
