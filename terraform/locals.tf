data "aws_caller_identity" "current" {}

locals {
  principal_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/voclabs"
  labRole          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  create_user_pool = var.existing_user_pool_id == "" ? true : false

}
