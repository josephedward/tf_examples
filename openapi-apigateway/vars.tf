
variable "AWS_REGION" {
  default = "us-east-1"
}

variable "s3_bucket" { default = "openapi-test-bucket-1" }



variable "sprint" { default = "1" }

variable "lambda_identity_timeout" { default = 1000 }
