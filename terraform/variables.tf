variable "name_prefix" {
  type    = string
  default = "tech-challenge-lambda"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "jwt_issuer" {
  type    = string
  default = "ordermanagement-auth"
}

variable "jwt_ttl_min" {
  type    = number
  default = 15
}

variable "jwt_secret" {
  type    = string
  default = "senhaboa123"
}

variable "api_uri" {
  type    = string
  default = "http://a68e11e2bdd0644a09102cf8c8e48e00-1652431674.us-east-1.elb.amazonaws.com:8080"
}
