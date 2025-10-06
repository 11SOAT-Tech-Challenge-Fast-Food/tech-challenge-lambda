resource "aws_lambda_function" "auth" {
  function_name    = "${var.name_prefix}-auth-lambda"
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  role             = local.labRole
  filename         = "auth.zip"
  source_code_hash = filebase64sha256("auth.zip")

  environment {
    variables = {
      USER_POOL_ID = var.existing_user_pool_id != "" ? var.existing_user_pool_id : aws_cognito_user_pool.users.id
      JWT_ISSUER   = var.jwt_issuer
      JWT_TTL_MIN  = tostring(var.jwt_ttl_min)
      JWT_SECRET   = var.jwt_secret
      DB_HOST      = "host"
      DB_PORT      = "5432"
      DB_NAME      = "ordermanagementdb"
      DB_USER      = "db_user"
      DB_PASSWORD  = "db_password"
    }
  }
}

resource "aws_lambda_function" "register_user" {
  function_name    = "${var.name_prefix}-register-user-lambda"
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  role             = local.labRole
  filename         = "registerUser.zip"
  source_code_hash = filebase64sha256("registerUser.zip")

  environment {
    variables = {
      USER_POOL_ID = var.existing_user_pool_id != "" ? var.existing_user_pool_id : aws_cognito_user_pool.users.id
      DB_HOST      = "host"
      DB_PORT      = "5432"
      DB_NAME      = "ordermanagementdb"
      DB_USER      = "db_user"
      DB_PASSWORD  = "db_password"
    }
  }
}

resource "aws_api_gateway_rest_api" "main" {
  name        = "tech-challenge-api-gateway"
  description = "API GATEWAY MAIN"
}

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "register" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "register"
}

resource "aws_api_gateway_method" "auth_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "register_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.register.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.auth.id
  http_method             = aws_api_gateway_method.auth_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

resource "aws_api_gateway_integration" "register_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.register.id
  http_method             = aws_api_gateway_method.register_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_user.invoke_arn
}

resource "aws_lambda_permission" "api_gw_auth" {
  statement_id  = "AllowAPIGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/${aws_api_gateway_stage.user.stage_name}/POST/auth"
}

resource "aws_lambda_permission" "api_gw_register_user" {
  statement_id  = "AllowAPIGatewayInvokeRegisterUser"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/${aws_api_gateway_stage.user.stage_name}/POST/register"
}

resource "aws_api_gateway_deployment" "api_deploy" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  depends_on = [
    aws_api_gateway_integration.auth_lambda,
    aws_api_gateway_integration.register_lambda
  ]
}

resource "aws_api_gateway_stage" "user" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.api_deploy.id
  stage_name    = "user"
}
