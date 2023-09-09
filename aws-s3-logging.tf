# Create an S3 bucket to collect our audit logs. If the account already has Global auditing enabled, this section can be disabled.
resource "aws_s3_bucket" "logging" {
  bucket_prefix = "${var.project_prefix}-${var.aws_account_id}-logging"

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

# Block Public Access to the bucket as it should never be needed.
resource "aws_s3_bucket_public_access_block" "logging" {
  bucket                  = aws_s3_bucket.logging.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket_policy.logging]
}

# Configure the bucket lifecycle to degrade storage tier after 30 days and delete after 90 days.
resource "aws_s3_bucket_lifecycle_configuration" "logging" {
  bucket = aws_s3_bucket.logging.id
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

# Configure bucket notifications to emit to EventBridge.
resource "aws_s3_bucket_notification" "logging" {
  bucket      = aws_s3_bucket.logging.id
  eventbridge = true
}

# Set the bucket policy to allow AWS log writing.
resource "aws_s3_bucket_policy" "logging" {
  bucket = aws_s3_bucket.logging.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "AllowSSLRequestsOnly",
        "Action": "s3:*",
        "Effect": "Deny",
        "Resource": [
            "${aws_s3_bucket.logging.arn}",
            "${aws_s3_bucket.logging.arn}/*"
        ],
        "Condition": {
            "Bool": {
                  "aws:SecureTransport": "false"
            }
        },
        "Principal": "*"
    },
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
