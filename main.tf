provider "aws" {
  region  = var.aws_region
  # profile = var.aws_profile
}

terraform {
  backend "s3" {
    bucket = "918573727633-portfolio-state"
    key    = "portfolio.terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    kms_key_id = "arn:aws:kms:us-east-1:918573727633:key/710cafd7-3970-4454-9d12-b72b7141d577"
  }
}
