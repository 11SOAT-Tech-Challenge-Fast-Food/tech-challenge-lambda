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
  default = "http://a2dbd1911ef6e4ae5885660baa1c673f-469276399.us-east-1.elb.amazonaws.com:8080"
}
