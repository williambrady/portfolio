# Create an S3 bucket to collect our audit logs. If the account already has Global auditing enabled, this section can be disabled.
resource "aws_s3_bucket" "logging" {
  bucket =  "${var.bucket_prefix}-${var.aws_account_id}-${var.aws_region}-logging"

  acl           = "log-delivery-write"
  region        = "${var.aws_region}"

  logging{
    target_bucket = "${var.bucket_prefix}-${var.aws_account_id}-${var.aws_region}-logging"
    target_prefix = "s3-logs/${var.bucket_prefix}-${var.aws_account_id}-${var.aws_region}-logging"
  }

  versioning {
    enabled = true
  }

  force_destroy = true

  tags = "${merge(map("Name","logging"), var.tags)}"
}

# Set the bucket policy to allow AWS log writing.
resource "aws_s3_bucket_policy" "logging" {
  bucket = "${aws_s3_bucket.logging.id}"

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
      "Resource": "${aws_s3_bucket.logging.arn}/${var.bucket_prefix}/AWSLogs/${var.aws_account_id}/Config/*",
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
  bucket = "${aws_s3_bucket.logging.id}"
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  depends_on = ["aws_s3_bucket_policy.logging"]
}
