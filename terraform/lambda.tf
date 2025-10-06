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
      USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.app.id
      JWT_ISSUER   = var.jwt_issuer
      JWT_TTL_MIN  = tostring(var.jwt_ttl_min)
      JWT_SECRET   = var.jwt_secret
      DB_HOST      = "ordermanagementdb-postgres.c7s8uwq2c3v1.us-east-1.rds.amazonaws.com"
      DB_PORT      = "5432"
      DB_NAME      = "ordermanagementdb"
      DB_USER      = "db_user"
      DB_PASSWORD  = "db_password"
      CLIENT_ID        = aws_cognito_user_pool_client.app.id
      DEFAULT_PASSWORD = "SENHABOa12345#"
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
      USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.app.id
      USER_POOL_ID = var.existing_user_pool_id != "" ? var.existing_user_pool_id : aws_cognito_user_pool.users.id
      DB_HOST      = "ordermanagementdb-postgres.c7s8uwq2c3v1.us-east-1.rds.amazonaws.com"
      DB_PORT      = "5432"
      DB_NAME      = "ordermanagementdb"
      DB_USER      = "db_user"
      DB_PASSWORD  = "db_password"
      DEFAULT_PASSWORD = "SENHABOa12345#"
    }
  }
}

# ---------- Auth Lambda permission ----------
resource "aws_lambda_permission" "api_gw_auth" {
  statement_id  = "AllowAPIGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# ---------- Register Lambda permission ----------
resource "aws_lambda_permission" "api_gw_register_user" {
  statement_id  = "AllowAPIGatewayInvokeRegisterUser"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_user.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}