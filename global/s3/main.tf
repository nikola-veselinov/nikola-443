provider "aws" {
  region                  = "eu-west-2"
  profile                 = "Nikola"
}
terraform {
  backend "s3" {
    bucket = "tozi-bucket-e-za-state"
    key    = "global/s3/terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table = "tazi-db-e-za-lock"
    encrypt = true
    profile = "Nikola"
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "tozi-bucket-e-za-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name = "tazi-db-e-za-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# resource "aws_kms_key" "mykey" {
#   description             = "This key is used to encrypt bucket objects"
#   deletion_window_in_days = 10
# }

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      # kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}