# S3 Info
output "aws_s3_bucket_logging" {
  value = "${aws_s3_bucket.logging.id}"
}
output "aws_s3_bucket_dataset" {
  value = "${aws_s3_bucket.dataset.id}"
}

# CloudTrail Info
output "aws_cloudtrail_portfolio" {
  value = "${"aws_cloudtrail.portfolio.id"}"
}

# IAM Info
output "aws_iam_instance_profile" {
  value = "${aws_iam_instance_profile.s3read.arn}"
}

# Bastion host information
output "aws_bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}
output "aws_bastion_iam_instance_profile" {
  value = "${aws_instance.bastion.iam_instance_profile}"
}
output "aws_bastion_keyname" {
  value = "${var.ec2_keyname}"
}
# VPC Info
output "aws_vpc_cidr"{
  value = "${aws_vpc.main.cidr_block}"
}
output "aws_vpc_public_subnet_a"{
  value = "${aws_subnet.public-subnet-a.cidr_block}, ${aws_subnet.public-subnet-a.availability_zone}"
}
output "aws_vpc_public_subnet_b"{
  value = "${aws_subnet.public-subnet-b.cidr_block}, ${aws_subnet.public-subnet-b.availability_zone}"
}
output "aws_vpc_private_subnet_a"{
  value = "${aws_subnet.private-subnet-a.cidr_block}, ${aws_subnet.private-subnet-a.availability_zone}"
}
output "aws_vpc_private_subnet_b"{
  value = "${aws_subnet.private-subnet-b.cidr_block}, ${aws_subnet.private-subnet-b.availability_zone}"
}
