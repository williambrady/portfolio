# Create a small instance to test scripts, connectivity, and troubleshoot as needed
resource "aws_instance" "bastion" {
  ami           = "ami-0323c3dd2da7fb37d"
  instance_type = "t3.micro"
  iam_instance_profile = "${aws_iam_instance_profile.s3read.id}"
  key_name = "${var.ec2_keyname}"
  vpc_security_group_ids = ["${aws_security_group.bastion_public.id}"]
  subnet_id = "${aws_subnet.public-subnet-a.id}"
  tags = "${merge(map("Name","bastion"), var.tags)}"
  volume_tags = "${merge(map("Name","bastion"), var.tags)}"
  user_data = "${file("aws-ec2-bastion-userdata.txt")}"
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = "${file("~/.ssh/${var.ec2_keyname}.pem")}"
  }
  provisioner "remote-exec" {
    inline = [
      "aws s3 cp s3://portfolio-918573727633-us-east-1-dataset/aws-ec2-query.py aws-ec2-query.py",
    ]
  }
  depends_on = ["aws_s3_bucket.dataset","aws_iam_instance_profile.s3read","aws_security_group.bastion_public","aws_vpc.main","aws_internet_gateway.main","aws_nat_gateway.main"]
}

# Create the Security Group for the instance
resource "aws_security_group" "bastion_public" {
  name        = "bastion_public"
  description = "Incoming"
  vpc_id      = "${aws_vpc.main.id}"
  tags = "${merge(map("Name","Bastion Public"), var.tags)}"
  ingress {
    description = "mgmt ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.mgmt_ip}/32"]
  }
# Commenting the internal SG Communications unless specifically needed.
#  ingress {
#    description = "self comms"
#    from_port   = 0
#    to_port     = 65535
#    protocol    = "tcp"
#    self        = true
#  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# Create an Instance Role to allow the EC2 instance to AssumeRole.
resource "aws_iam_role" "s3read" {
  name = "${var.bucket_prefix}-role"
  path = "/instance-profile/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid" : ""
    }
  ]
}
EOF
}

# Create a Read-Only S3 policy to allow the instance to reach the S3 Bucket
resource "aws_iam_policy" "s3read" {
  name        = "${var.bucket_prefix}-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["s3:*"],
      "Effect": "Allow",
      "Resource": ["${aws_s3_bucket.dataset.arn}"]
    },
    {
      "Action": ["s3:*"],
      "Effect": "Allow",
      "Resource": ["${aws_s3_bucket.dataset.arn}/*"]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "s3read" {
  role       = "${aws_iam_role.s3read.name}"
  policy_arn = "${aws_iam_policy.s3read.arn}"
  depends_on = ["aws_iam_policy.s3read"]
}

#Attach the Policy to the Instance Role
resource "aws_iam_instance_profile" "s3read" {
  name = "${var.bucket_prefix}-profile"
  role = "${aws_iam_role.s3read.name}"
  depends_on = ["aws_iam_role.s3read","aws_iam_policy.s3read"]
}
