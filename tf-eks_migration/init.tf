terraform {
  backend "s3" {
    bucket  = "test-bucket-hackedu"
    key     = "platform/terraform.tfstate"
    region  = "us-east-1"
    profile = "cloud_user"
  }
}

provider "aws" {
 
  region  = "us-east-1"
  profile = "cloud_user"
}

# Link in remote state
data "terraform_remote_state" "content" {
  backend = "s3"

  config = {
    bucket  = "hackedu-terraform-development-testbucket"
    key     = "content/terraform.tfstate"
    region  = "us-east-1"
    profile = "cloud-user"
  }
}

data "aws_caller_identity" "current" {}

data "aws_elb_service_account" "current" {}
