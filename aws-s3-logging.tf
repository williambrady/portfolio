# Create an S3 bucket to collect our audit logs. If the account already has Global auditing enabled, this section can be disabled.
resource "aws_s3_bucket" "logging" {
  bucket = "${var.project_prefix}-${var.aws_account_id}-${var.aws_region}-logging"

  # acl    = "log-delivery-write"
  # region = var.aws_region

  # logging {
  #   target_bucket = "${var.project_prefix}-${var.aws_account_id}-${var.aws_region}-logging"
  #   target_prefix = "s3-logs/${var.project_prefix}-${var.aws_account_id}-${var.aws_region}-logging"
  # }

  # Typically force_destroy is not set, but since this project is a test and will be created/destroyed repeatedly it is allowable.
  force_destroy = true

  tags = var.tags
}

# Set bucket versioning
resource "aws_s3_bucket_versioning" "logging" {
  bucket = aws_s3_bucket.logging.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Set bucket as logging destination
# resource "aws_s3_bucket_acl" "logging" {
#   bucket = aws_s3_bucket.logging.id

#   acl = "log-delivery-write"
# }

# Set the bucket policy to allow AWS log writing.
resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.logging.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Config ACL Check",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"
        ]
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.logging.arn}",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    },
    {
      "Sid": "Allow bucket write by Config",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"
        ]
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.logging.arn}/${var.project_prefix}/AWSLogs/${var.aws_account_id}/Config/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        },
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    },
    {
      "Sid": "Cloudtrail ACL Check",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.logging.arn}"
    },
    {
      "Sid": "Cloudtrail Bucket Write",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
        },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.logging.arn}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
POLICY

}

# Block Public Access to the bucket as it should never be needed.
resource "aws_s3_bucket_public_access_block" "logging" {
  bucket                  = aws_s3_bucket.logging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket_policy.logging]
}

