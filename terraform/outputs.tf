output "auth_lambda_name" {
  description = "Nome da função Lambda de autenticação"
  value       = aws_lambda_function.auth.function_name
}

output "register_user_lambda_name" {
  description = "Nome da função Lambda de registro de usuário"
  value       = aws_lambda_function.register_user.function_name
}

output "api_base_url" {
  description = "URL base da API Gateway"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.region}.amazonaws.com/user/"
}

output "auth_endpoint" {
  description = "Endpoint de autenticação (POST /auth)"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.region}.amazonaws.com/user/auth"
}

output "register_endpoint" {
  description = "Endpoint de registro (POST /register)"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.region}.amazonaws.com/user/register"
}
