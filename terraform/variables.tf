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
  type = string
}

variable "api_uri" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_host" {
  type = string
}