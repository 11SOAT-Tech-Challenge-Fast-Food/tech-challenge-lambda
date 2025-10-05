resource "aws_cognito_user_pool" "users" {
  name = "${var.name_prefix}-cpf-user-pool"

  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  alias_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    developer_only_attribute = false
    string_attribute_constraints {
      min_length = 5
      max_length = 255
    }
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name            = "${var.name_prefix}-cpf-app-client"
  user_pool_id    = aws_cognito_user_pool.users.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}