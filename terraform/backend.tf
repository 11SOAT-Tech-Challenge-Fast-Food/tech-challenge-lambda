terraform {
  cloud {
    organization = "fiap-pos-tc"

    workspaces {
      name = "lambda-infra"
    }
  }
}