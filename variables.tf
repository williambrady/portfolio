variable "aws_account_id" {
  description = "AWS Account Number"
}

# variable "aws_profile" {
#   description = "Profile name in ~/.aws/credentials used to access target account"
# }

variable "aws_region" {
  description = "default region to build in"
}

variable "project_prefix" {
  description = "project prefix will brand assets"
}

variable "tags" {
  description = "set default tags for assets"
  default = {
    "owner"       = "william.brady"
    "lob"         = "cloudops"
    "contact"     = "will@crofton.cloud"
    "projectid"   = "portfolio-0001"
    "component"   = "infrastructure"
    "disposition" = "development"
  }
}

variable "infile" {
  description = "original CSV file to build from"
  default     = "dataset.csv"
}

