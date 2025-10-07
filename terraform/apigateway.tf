resource "aws_api_gateway_rest_api" "main" {
  name        = "tech-challenge-api-gateway"
  description = "API for Auth + Register + EKS proxy"
}

# ---------- Auth ----------
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_method" "auth_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.auth.id
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

# ---------- Register ----------
resource "aws_api_gateway_resource" "register" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "register"
}

resource "aws_api_gateway_method" "register_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.register.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "register_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.register.id
  http_method             = aws_api_gateway_method.register_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_user.invoke_arn
}

# ---------- Authorizer ----------
resource "aws_api_gateway_authorizer" "jwt_authorizer" {
  name                             = "jwt-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.main.id
  authorizer_uri                   = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.jwt_authorizer.arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  type                             = "REQUEST"
}


# ---------- Deployment + Stage ----------
resource "aws_api_gateway_deployment" "api_deploy" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeploy_hash = sha1(jsonencode([
      aws_api_gateway_rest_api.main.id,
      aws_api_gateway_authorizer.jwt_authorizer.id,
      aws_api_gateway_integration.auth_lambda.id,
      aws_api_gateway_integration.register_lambda.id,
      aws_api_gateway_integration.eks_customer_get.id,
      aws_api_gateway_integration.eks_customer_post.id,
      aws_api_gateway_integration.eks_customer_id_put.id,
      aws_api_gateway_integration.eks_customer_id_delete.id,
      aws_api_gateway_integration.eks_health_get.id,
      aws_api_gateway_integration.eks_product_get.id,
      aws_api_gateway_integration.eks_product_category_get.id,
      aws_api_gateway_integration.eks_product_id_get.id,
      aws_api_gateway_integration.eks_product_id_delete.id,
      aws_api_gateway_integration.eks_order_id_get.id,
      aws_api_gateway_integration.eks_order_get.id,
      aws_api_gateway_integration.eks_order_id_put.id,
      aws_api_gateway_integration.eks_order_id_delete.id,
      aws_api_gateway_integration.eks_payment_post.id,
      aws_api_gateway_integration.eks_payment_id_get.id,
      aws_api_gateway_integration.eks_payment_webhook_post.id,
      aws_api_gateway_integration.eks_docs_get.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.auth_lambda,
    aws_api_gateway_integration.register_lambda,
    aws_api_gateway_authorizer.jwt_authorizer,
    aws_api_gateway_integration.eks_customer_get,
    aws_api_gateway_integration.eks_customer_post,
    aws_api_gateway_integration.eks_customer_id_put,
    aws_api_gateway_integration.eks_customer_id_delete,
    aws_api_gateway_integration.eks_health_get,
    aws_api_gateway_integration.eks_product_get,
    aws_api_gateway_integration.eks_product_post,
    aws_api_gateway_integration.eks_product_category_get,
    aws_api_gateway_integration.eks_product_id_get,
    aws_api_gateway_integration.eks_product_id_delete,
    aws_api_gateway_integration.eks_order_get,
    aws_api_gateway_integration.eks_order_id_get,
    aws_api_gateway_integration.eks_order_id_put,
    aws_api_gateway_integration.eks_order_id_delete,
    aws_api_gateway_integration.eks_payment_post,
    aws_api_gateway_integration.eks_payment_id_get,
    aws_api_gateway_integration.eks_payment_webhook_post,
    aws_api_gateway_integration.eks_docs_get
  ]
}


resource "aws_api_gateway_stage" "user" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.api_deploy.id
  stage_name    = "user"
}
