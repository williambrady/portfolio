variable "aws_account_id" {}
variable "aws_profile" {}
variable "aws_region" {}
variable "project_name" {}
variable "ec2_keyname" {}
variable "mgmt_ip" {}

variable "bucket_prefix" {
  default = "portfolio"
}

variable "vpc_cidr" {}
variable "vpc_subnet_pub_a" {}
variable "vpc_subnet_pub_b" {}
variable "vpc_subnet_priv_a" {}
variable "vpc_subnet_priv_b" {}

variable "tags" {
  default = {
    "owner"   = "william.brady"
    "lob"     = "cloudops"
    "contact" = "will@crofton.cloud"
    "projectid" = "portfolio-0002"
    "component" = "infrastructure"
    "disposition" = "development"
  }
}
