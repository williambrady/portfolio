# Validate how to use the terraform random resources.
resource "random_pet" "george" {
  length    = 1
  separator = "-"
}

resource "aws_s3_bucket" "george" {
  depends_on    = [aws_s3_bucket.logging]
  bucket_prefix = "${var.project_prefix}-${var.aws_account_id}-${random_pet.george.id}"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_logging" "george" {
  bucket        = aws_s3_bucket.george.id
  target_bucket = aws_s3_bucket.logging.id
  target_prefix = "s3-logs/${var.project_prefix}-${var.aws_account_id}-${random_pet.george.id}"
}

resource "aws_s3_bucket_versioning" "george" {
  bucket = aws_s3_bucket.george.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block Public Access to the bucket as it should never be needed.
resource "aws_s3_bucket_public_access_block" "george" {
  bucket                  = aws_s3_bucket.george.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure bucket lifecycle to move objects to IA after 30 days and delete after 90 days.
resource "aws_s3_bucket_lifecycle_configuration" "george" {
  bucket = aws_s3_bucket.george.id
  rule {
    id = "log_expiration"
    filter {}
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 90
    }
  }
}

# Configure bucket notifications to SNS and emit to EventBridge.
resource "aws_s3_bucket_notification" "george" {
  bucket      = aws_s3_bucket.george.id
  eventbridge = true
  topic {
    topic_arn = var.sns_topic_arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# Setup bucket policy to enforce SSL
resource "aws_s3_bucket_policy" "george" {
  bucket = aws_s3_bucket.george.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "AllowSSLRequestsOnly",
        "Action": "s3:*",
        "Effect": "Deny",
        "Resource": [
            "${aws_s3_bucket.george.arn}",
            "${aws_s3_bucket.george.arn}/*"
        ],
        "Condition": {
            "Bool": {
                  "aws:SecureTransport": "false"
            }
        },
        "Principal": "*"
    }
  ]
}
POLICY

}
