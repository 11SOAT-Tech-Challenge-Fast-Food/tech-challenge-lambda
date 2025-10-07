# Base /api
resource "aws_api_gateway_resource" "eks" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "eks_customer" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks.id
  path_part   = "customer"
}

resource "aws_api_gateway_resource" "eks_health" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks.id
  path_part   = "health"
}

resource "aws_api_gateway_resource" "eks_product" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks.id
  path_part   = "product"
}

resource "aws_api_gateway_resource" "eks_order" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks.id
  path_part   = "order"
}

resource "aws_api_gateway_resource" "eks_payment" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks.id
  path_part   = "payment"
}

resource "aws_api_gateway_resource" "eks_docs" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks.id
  path_part   = "docs"
}

# --------------------HEALTH-----------------------------
# -------------------------------------------------
# /api/health [GET]
resource "aws_api_gateway_method" "eks_health_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_health.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "eks_health_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_health.id
  http_method             = aws_api_gateway_method.eks_health_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.api_uri}:8080/actuator/health/liveness"
}

# -------------------------------------------------
# /api/swagger [GET] - Público (sem JWT)
# -------------------------------------------------
resource "aws_api_gateway_method" "eks_docs_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_docs.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "eks_docs_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_docs.id
  http_method             = aws_api_gateway_method.eks_docs_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/swagger-ui.html"
}


# --------------------CUSTOMER-----------------------------
# /api/customer [POST] - Protegido com JWT
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
  uri                     = "http://${var.api_uri}:8080/customer"
}

# -------------------------------------------------
# /api/customer [GET] - Protegido com JWT
resource "aws_api_gateway_method" "eks_customer_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_customer.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id
}

resource "aws_api_gateway_integration" "eks_customer_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_customer.id
  http_method             = aws_api_gateway_method.eks_customer_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.api_uri}:8080/customer"
}

# -------------------------------------------------
# /api/customer/{id} [GET] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_customer_id_param" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_customer.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "eks_customer_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_customer_id_param.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "eks_customer_id_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_customer_id_param.id
  http_method             = aws_api_gateway_method.eks_customer_id_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/customer/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# -------------------------------------------------
# /api/customer/email/{email} [GET] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_customer_email" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_customer.id
  path_part   = "email"
}

resource "aws_api_gateway_resource" "eks_customer_email_param" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_customer_email.id
  path_part   = "{email}"
}

resource "aws_api_gateway_method" "eks_customer_email_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_customer_email_param.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.path.email" = true
  }
}

resource "aws_api_gateway_integration" "eks_customer_email_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_customer_email_param.id
  http_method             = aws_api_gateway_method.eks_customer_email_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/customer/email/{email}"

  request_parameters = {
    "integration.request.path.email" = "method.request.path.email"
  }
}

# -------------------------------------------------
# /api/customer/cpf/{cpf} [GET] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_customer_cpf" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_customer.id
  path_part   = "cpf"
}

resource "aws_api_gateway_resource" "eks_customer_cpf_param" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_customer_cpf.id
  path_part   = "{cpf}"
}

resource "aws_api_gateway_method" "eks_customer_cpf_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_customer_cpf_param.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.path.cpf" = true
  }
}

# Integração HTTP Proxy para /api/customer/cpf/{cpf}
resource "aws_api_gateway_integration" "eks_customer_cpf_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_customer_cpf_param.id
  http_method             = aws_api_gateway_method.eks_customer_cpf_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/customer/cpf/{cpf}"

  request_parameters = {
    "integration.request.path.cpf" = "method.request.path.cpf"
  }
}

# -------------------------------------------------
# /api/customer/{id} [PUT] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_method" "eks_customer_id_put" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_customer_id_param.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_models = {
    "application/json" = "Empty"
  }

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "eks_customer_id_put" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_customer_id_param.id
  http_method             = aws_api_gateway_method.eks_customer_id_put.http_method
  integration_http_method = "PUT"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/customer/{id}"


  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
  passthrough_behavior = "WHEN_NO_MATCH"
  content_handling     = "CONVERT_TO_TEXT"
}

# -------------------------------------------------
# /api/customer/{id} [DELETE] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_method" "eks_customer_id_delete" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_customer_id_param.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "eks_customer_id_delete" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_customer_id_param.id
  http_method             = aws_api_gateway_method.eks_customer_id_delete.http_method
  integration_http_method = "DELETE"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/customer/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# --------------------PRODUCT-----------------------------
# -------------------------------------------------
# /api/product [POST] - Protegido com JWT
resource "aws_api_gateway_method" "eks_product_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_product.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id
}

resource "aws_api_gateway_integration" "eks_product_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_product.id
  http_method             = aws_api_gateway_method.eks_product_post.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.api_uri}:8080/product"
}
# -------------------------------------------------
# /api/product [GET] - Publico
resource "aws_api_gateway_method" "eks_product_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_product.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "eks_product_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_product.id
  http_method             = aws_api_gateway_method.eks_product_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.api_uri}:8080/product"
}
# -------------------------------------------------
# /api/product/category/{category} [GET] - Público
resource "aws_api_gateway_resource" "eks_product_category" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_product.id
  path_part   = "category"
}

resource "aws_api_gateway_resource" "eks_product_category_param" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_product_category.id
  path_part   = "{category}"
}

resource "aws_api_gateway_method" "eks_product_category_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_product_category_param.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.category" = true
  }
}

resource "aws_api_gateway_integration" "eks_product_category_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_product_category_param.id
  http_method             = aws_api_gateway_method.eks_product_category_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/product/category/{category}"

  request_parameters = {
    "integration.request.path.category" = "method.request.path.category"
  }
}

# -------------------------------------------------
# /api/product/{id} [GET] - Público
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_product_id_param" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_product.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "eks_product_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_product_id_param.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "eks_product_id_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_product_id_param.id
  http_method             = aws_api_gateway_method.eks_product_id_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/product/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# -------------------------------------------------
# /api/product [PUT] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_method" "eks_product_put" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_product.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  # 👇 essencial para aceitar JSON body
  request_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "eks_product_put" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_product.id
  http_method             = aws_api_gateway_method.eks_product_put.http_method
  integration_http_method = "PUT"
  type                    = "HTTP_PROXY"

  # 👇 backend espera /product, sem {id}
  uri = "http://${var.api_uri}:8080/product"

  passthrough_behavior = "WHEN_NO_MATCH"
  content_handling     = "CONVERT_TO_TEXT"
}

# -------------------------------------------------
# /api/product/{id} [DELETE] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_method" "eks_product_id_delete" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_product_id_param.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "eks_product_id_delete" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_product_id_param.id
  http_method             = aws_api_gateway_method.eks_product_id_delete.http_method
  integration_http_method = "DELETE"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/product/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}
# --------------------ORDER-----------------------------
# -------------------------------------------------
# /api/order [POST] - Protegido com JWT

resource "aws_api_gateway_method" "eks_order_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_order.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  # 👇 essencial para aceitar JSON body
  request_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "eks_order_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_order.id
  http_method             = aws_api_gateway_method.eks_order_post.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/order"

  passthrough_behavior = "WHEN_NO_MATCH"
  content_handling     = "CONVERT_TO_TEXT"
}

# -------------------------------------------------
# /api/order [GET] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_method" "eks_order_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_order.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id
}

resource "aws_api_gateway_integration" "eks_order_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_order.id
  http_method             = aws_api_gateway_method.eks_order_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.api_uri}:8080/order"
}

# -------------------------------------------------
# /api/order/{id} [GET] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_order_id_param" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_order.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "eks_order_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_order_id_param.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "eks_order_id_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_order_id_param.id
  http_method             = aws_api_gateway_method.eks_order_id_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"

  uri = "http://${var.api_uri}:8080/order/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# -------------------------------------------------
# /api/order/{id} [PUT] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_method" "eks_order_id_put" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_order_id_param.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.path.id" = true
  }

  request_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "eks_order_id_put" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_order_id_param.id
  http_method             = aws_api_gateway_method.eks_order_id_put.http_method
  integration_http_method = "PUT"
  type                    = "HTTP_PROXY"

  # 🔗 Proxy direto pro backend
  uri = "http://${var.api_uri}:8080/order/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }

  passthrough_behavior = "WHEN_NO_MATCH"
  content_handling     = "CONVERT_TO_TEXT"
}

# -------------------------------------------------
# /api/order/{id} [DELETE] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_method" "eks_order_id_delete" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_order_id_param.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "eks_order_id_delete" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_order_id_param.id
  http_method             = aws_api_gateway_method.eks_order_id_delete.http_method
  integration_http_method = "DELETE"
  type                    = "HTTP_PROXY"

  # 🔗 Proxy direto para o backend
  uri = "http://${var.api_uri}:8080/order/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# --------------------PAYMENT-----------------------------
# /api/payment [POST] - Protegido com JWT
resource "aws_api_gateway_method" "eks_payment_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_payment.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id
}

resource "aws_api_gateway_integration" "eks_payment_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_payment.id
  http_method             = aws_api_gateway_method.eks_payment_post.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"

  # 🔗 Proxy direto para o backend
  uri = "http://${var.api_uri}:8080/payment"

  passthrough_behavior = "WHEN_NO_MATCH"
  content_handling     = "CONVERT_TO_TEXT"
}

# -------------------------------------------------
# /api/payment/{id} [GET] - Protegido com JWT
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_payment_id_param" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_payment.id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "eks_payment_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_payment_id_param.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_parameters = {
    "method.request.path.id" = true
  }
}

resource "aws_api_gateway_integration" "eks_payment_id_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_payment_id_param.id
  http_method             = aws_api_gateway_method.eks_payment_id_get.http_method
  integration_http_method = "GET"
  type                    = "HTTP_PROXY"

  # 🔗 Proxy direto para o backend
  uri = "http://${var.api_uri}:8080/payment/{id}"

  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}
# -------------------------------------------------
# /api/payment/webhook [POST] - Público (sem JWT)
# -------------------------------------------------
resource "aws_api_gateway_resource" "eks_payment_webhook" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.eks_payment.id
  path_part   = "webhook"
}

resource "aws_api_gateway_method" "eks_payment_webhook_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.eks_payment_webhook.id
  http_method   = "POST"
  authorization = "NONE" # público
}

resource "aws_api_gateway_integration" "eks_payment_webhook_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.eks_payment_webhook.id
  http_method             = aws_api_gateway_method.eks_payment_webhook_post.http_method
  integration_http_method = "POST"
  type                    = "HTTP_PROXY"

  # 🔗 Proxy direto para o backend
  uri = "http://${var.api_uri}:8080/payment/webhook"

  passthrough_behavior = "WHEN_NO_MATCH"
  content_handling     = "CONVERT_TO_TEXT"
}
