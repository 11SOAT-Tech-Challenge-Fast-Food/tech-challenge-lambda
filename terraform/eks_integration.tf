# Base /api
resource "aws_api_gateway_resource" "eks" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

# -------------------------------------------------
# /api/customer [POST] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_method" "eks_customer_post" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.eks_customer.id
  http_method = "POST"

  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id
}

resource "aws_api_gateway_integration" "eks_customer_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_customer.id
  http_method             = aws_api_gateway_method.eks_customer_post.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri                     = "${var.api_uri}/customer"
}

# -------------------------------------------------
# /api/product [GET] - Público
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_product" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks.id
  path_part   = "product"
}

# /api/product/category
resource "aws_api_gateway_resource" "eks_product_category" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_product.id
  path_part   = "category"
}

# /api/product/category/{category}
resource "aws_api_gateway_resource" "eks_product_category_param" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_product_category.id
  path_part   = "{category}"
}

# ---------- Método público (GET) ----------
resource "aws_api_gateway_method" "eks_product_category_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_product_category_param.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  # Define o parâmetro de path
  request_parameters = {
    "method.request.path.category" = true
  }
}

# ---------- Integração HTTP Proxy ----------
resource "aws_api_gateway_integration" "eks_product_category_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_product_category_param.id
  http_method             = aws_api_gateway_method.eks_product_category_get.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"

  # O {category} é substituído automaticamente pelo valor da URL
  uri = "${var.api_uri}/product/category/{category}"

  # Mapeia o parâmetro do método para a integração
  request_parameters = {
    "integration.request.path.category" = "method.request.path.category"
  }
}

# -------------------------------------------------
# /api/health [GET] - Público
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_health" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks.id
  path_part   = "health"
}

resource "aws_api_gateway_method" "eks_health_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_health.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id
}

resource "aws_api_gateway_integration" "eks_health_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_health.id
  http_method             = aws_api_gateway_method.eks_health_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "${var.api_uri}/actuator/health/liveness"
}

# -------------------------------------------------
# /api/customer [GET] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_customer" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks.id
  path_part   = "customer"
}

resource "aws_api_gateway_method" "eks_customer_get" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.eks_customer.id
  http_method = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id
}

resource "aws_api_gateway_integration" "eks_customer_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_customer.id
  http_method             = aws_api_gateway_method.eks_customer_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "${var.api_uri}/customer"
}