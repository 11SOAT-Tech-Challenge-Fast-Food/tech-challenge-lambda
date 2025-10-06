# ---------- Cognito User Pool ----------
resource "aws_cognito_user_pool" "users" {
  name = "${var.name_prefix}-user-pool"

  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  alias_attributes = ["email"]

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false
    string_attribute_constraints {
      min_length = 5
      max_length = 255
    }
  }
}

# ---------- Cognito App Client ----------
resource "aws_cognito_user_pool_client" "app" {
  name            = "${var.name_prefix}-app-client"
  user_pool_id    = aws_cognito_user_pool.users.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  prevent_user_existence_errors = "ENABLED"
}

# ---------- Cognito Authorizer ----------
resource "aws_api_gateway_authorizer" "jwt_authorizer" {
  name            = "cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.users.arn]
  identity_source = "method.request.header.Authorization"
}