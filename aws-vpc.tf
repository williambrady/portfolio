# Create a VPC to house compatible infrastructure, in this case RDS, Lambda, or EC2 dev instances
resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  depends_on = ["aws_s3_bucket.dataset"]
  tags = "${var.tags}"
}

# Create an Internet Gateway to allow assets to access the Internet for updates or additional business data.
# This section can be altered if external access is not required.
resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags = "${var.tags}"
}

# Determine which AZs are available in the deployment target region
data "aws_availability_zones" "available" {
  state = "available"
}
# Create two Public Subnets for resilience
resource "aws_subnet" "public-subnet-a" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "${var.vpc_subnet_pub_a}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = "true"
  tags = "${merge(map("Name","pub-a"), var.tags)}"
}
resource "aws_subnet" "public-subnet-b" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.vpc_subnet_pub_b}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    map_public_ip_on_launch = "true"
    tags = "${merge(map("Name","pub-b"), var.tags)}"
}
# Create two Private subnets for resilience
resource "aws_subnet" "private-subnet-a" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.vpc_subnet_priv_a}"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    tags = "${merge(map("Name","priv-a"), var.tags)}"
}
resource "aws_subnet" "private-subnet-b" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.vpc_subnet_priv_b}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
    tags = "${merge(map("Name","priv-b"), var.tags)}"
}

###
# Create a public route table to allow public-subnet VPC resources to pull Internet updates as needed
resource "aws_route_table" "public-route" {
   vpc_id = "${aws_vpc.main.id}"
   tags = "${var.tags}"
   route {
       cidr_block = "0.0.0.0/0"
       gateway_id = "${aws_internet_gateway.main.id}"
   }
   depends_on = ["aws_internet_gateway.main"]
}

# Associate the public route table to the public subnets
resource "aws_route_table_association" "public-a-assoc" {
    subnet_id = "${aws_subnet.public-subnet-a.id}"
    route_table_id = "${aws_route_table.public-route.id}"
}

resource "aws_route_table_association" "public-b-assoc" {
    subnet_id = "${aws_subnet.public-subnet-b.id}"
    route_table_id = "${aws_route_table.public-route.id}"
}

###
# Create a private route table to direct private subnets through the NAT Gateway.
# Adjust / remove this if private assets are not to have external access.
resource "aws_route_table" "private-route" {
    vpc_id = "${aws_vpc.main.id}"
    tags = "${var.tags}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.main.id}"
    }
    depends_on = ["aws_nat_gateway.main"]
}

# Associate the private route table to the private subnets
resource "aws_route_table_association" "private-a-assoc" {
    subnet_id = "${aws_subnet.private-subnet-a.id}"
    route_table_id = "${aws_route_table.private-route.id}"
}
resource "aws_route_table_association" "private-b-assoc" {
    subnet_id = "${aws_subnet.private-subnet-b.id}"
    route_table_id = "${aws_route_table.private-route.id}"
}

# Provision an EIP for the NAT Gateway
resource "aws_eip" "main" {
  vpc = "true"
  depends_on = ["aws_internet_gateway.main"]
}

resource "aws_nat_gateway" "main" {
  allocation_id = "${aws_eip.main.id}"
  subnet_id     = "${aws_subnet.public-subnet-a.id}"
  depends_on = ["aws_eip.main"]
}

# Get those flow logs for visibility. They assist with troubleshooting and security investigations.
resource "aws_flow_log" "vpcflow" {
  iam_role_arn    = "${aws_iam_role.vpcflow.arn}"
  log_destination = "${aws_cloudwatch_log_group.vpcflow.arn}"
  traffic_type    = "ALL"
  vpc_id          = "${aws_vpc.main.id}"
}
# Get events into Cloudwatch to allow alerting
resource "aws_cloudwatch_log_group" "vpcflow" {
  name = "/aws/vpc/flow/${aws_vpc.main.id}"
}

# Create an IAM Role for VPC flow logs
resource "aws_iam_role" "vpcflow" {
  name = "vpcflow"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpcflow" {
  name = "vpcflow"
  role = "${aws_iam_role.vpcflow.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
