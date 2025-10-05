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

variable "existing_user_pool_id" {
  description = "ID de um user pool já existente (deixe em branco para criar um novo)"
  type        = string
  default     = ""
}