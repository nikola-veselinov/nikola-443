provider "aws" {
  region                  = "eu-west-2"
  profile                 = "Nikola"
}
terraform {
  backend "s3" {
    bucket = "tozi-bucket-e-za-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table = "tazi-db-e-za-lock"
    encrypt = true
    profile = "Nikola"
  }
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "terraform-up-and-running777"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  skip_final_snapshot = true
  db_name             = var.db_name
  username = "admin"
  password = data.aws_ssm_parameter.foo.value
}

data "aws_ssm_parameter" "foo" {
  name = "nikola-db-pass"
}