# terraform {
#   required_version = ">= 0.12, < 0.13"
# }

provider "aws" {
  region                  = "eu-west-2"
  profile                 = "Nikola"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"
}