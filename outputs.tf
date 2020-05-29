# S3 Info
output "s3_bucket_logging" {
  value = "${aws_s3_bucket.logging.id}"
}
output "s3_bucket_dataset" {
  value = "${aws_s3_bucket.dataset.id}"
}

# CloudTrail Info
output "cloudtrail_portfolio" {
  value = "${"aws_cloudtrail.portfolio.id"}"
}

# IAM Info
output "iam_instance_profile" {
  value = "${aws_iam_instance_profile.s3read.arn}"
}

# Bastion host information
output "bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}
output "bastion_iam_instance_profile" {
  value = "${aws_instance.bastion.iam_instance_profile}"
}
output "bastion_keyname" {
  value = "${var.ec2_keyname}"
}

output "aws_vpc_cidr"{
  value = "${aws_vpc.main.cidr_block}"
}
