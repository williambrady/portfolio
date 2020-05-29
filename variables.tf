variable "aws_account_id" { description = "AWS Account Number" }
variable "aws_profile" { description = "Profile name in ~/.aws/credentials used to access target account" }
variable "aws_region" { description = "default region to build in" }
variable "bucket_prefix" {
  description = "bucket prefix will brand assets"
  default = "portfolio"
}
variable "ec2_keyname" { description = "EC2 SSH Key Name" }
variable "mgmt_ip" { description = "IP Address of the deployment system, required for debugging" }
variable "bucket_key_prefix" {
  description = ""
  default = "portfolio-config"
}
variable "vpc_cidr" { description = "segmented network" }
variable "vpc_subnet_pub_a" {}
variable "vpc_subnet_pub_b" {}
variable "vpc_subnet_priv_a" {}
variable "vpc_subnet_priv_b" {}
variable "tags" {
  description = "set default tags for assets"
  default = {
    "owner"   = "william.brady"
    "lob"     = "cloudops"
    "contact" = "will@crofton.cloud"
    "projectid" = "portfolio-0002"
    "component" = "infrastructure"
    "disposition" = "development"
  }
}
