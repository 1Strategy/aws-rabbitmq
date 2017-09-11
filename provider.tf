provider "aws" {
  region  = "us-west-2"
  profile = "management"
  assume_role {
    role_arn     = "arn:aws:iam::842337631775:role/1S-Admins"
    session_name = "terraform"
    external_id  = "pavel"
  }
}


terraform {
  backend "s3" {
    bucket = "1s-terraform-tfstate"
    region = "us-west-2"
    key = "zulilly/rabbitmq/terraform.tfstate"
    dynamodb_table = "1s-terraform-state-locking"
    encrypt = true
    profile = "management"
    role_arn     = "arn:aws:iam::842337631775:role/1S-Admins"
  }
}