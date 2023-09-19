variable "aws_account_id" {
  description = "AWS Account Number"
}

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
    "projectid"   = "https://github.com/williambrady/portfolio"
    "component"   = "infrastructure"
    "disposition" = "development"
  }
}

variable "infile" {
  description = "original CSV file to build from"
  default     = "dataset.csv"
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN"
  default     = "arn:aws:sns:us-east-1:918573727633:cis-notifications"
}