# Just keep Amplify App + Branch
resource "aws_amplify_app" "frontend" {
  name         = "file-upload-ui"
  repository   = "https://github.com/ramzpm/file-upload-ui"
  platform     = "WEB"
  access_token = var.access_token

  environment_variables = {
    REACT_APP_API_URL = aws_apigatewayv2_api.file_upload_api.api_endpoint
  }

  enable_branch_auto_build    = true
  enable_branch_auto_deletion = true
  enable_auto_branch_creation = false
}

resource "aws_amplify_branch" "main" {
  app_id            = aws_amplify_app.frontend.id
  branch_name       = "main"
  stage             = "PRODUCTION"
  enable_auto_build = true
}
