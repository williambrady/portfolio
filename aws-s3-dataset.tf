resource "aws_s3_bucket" "dataset" {
  depends_on = ["aws_s3_bucket.dataset"]
  bucket =  "${var.bucket_prefix}-${var.aws_account_id}-${var.aws_region}-dataset"

  acl           = "private"
  region        = "${var.aws_region}"

  logging{
    target_bucket = "${aws_s3_bucket.logging.id}"
    target_prefix = "s3-logs/${var.bucket_prefix}-${var.aws_account_id}-${var.aws_region}-dataset"
  }

  versioning {
    enabled = true
  }

  tags = "${merge(map("Name","dataset"), var.tags)}"
}

# Block Publiic Access to the bucket as it should never be needed.
resource "aws_s3_bucket_public_access_block" "dataset" {
  bucket = "${aws_s3_bucket.dataset.id}"
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}
# Upload indexed_dataset.csv to the bucket for accessibility.
resource "aws_s3_bucket_object" "dataset" {
  depends_on = ["aws_s3_bucket.dataset"]
  bucket = "${aws_s3_bucket.dataset.id}"
  key    = "indexed_dataset.csv"
  source = "./indexed_dataset.csv"
  tags = "${merge(map("Name","indexed_dataset.csv"), var.tags)}"
}
# Upload the data handler for the ec2-query.py for testing.
resource "aws_s3_bucket_object" "ec2_query" {
  depends_on = ["aws_s3_bucket.dataset"]
  bucket = "${aws_s3_bucket.dataset.id}"
  key    = "aws-ec2-query.py"
  source = "./aws-ec2-query.py"
  tags = "${merge(map("Name","aws-ec2-query.py"), var.tags)}"
}
# Upload the lambda function.
resource "aws_s3_bucket_object" "lambda_function" {
  depends_on = ["aws_s3_bucket.dataset"]
  bucket = "${aws_s3_bucket.dataset.id}"
  key    = "lambda_function.zip"
  source = "./aws-lambda-portfolio-payload.zip"
  tags = "${merge(map("Name","aws-lambda-portfolio-payload.zip"), var.tags)}"
}
# Upload original dataset.csv to the bucket for accessibility.
resource "aws_s3_bucket_object" "og_dataset" {
  depends_on = ["aws_s3_bucket.dataset"]
  bucket = "${aws_s3_bucket.dataset.id}"
  key    = "dataset.csv"
  source = "./dataset.csv"
  tags = "${merge(map("Name","dataset.csv"), var.tags)}"
}
