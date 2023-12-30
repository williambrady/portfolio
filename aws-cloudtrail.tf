# Setup Cloudtrail so the project assets have visibility for troubleshooting and security review

# Identify the KMS Key
data "aws_kms_alias" "cloudtrail" {
  name = "alias/cloudtrail"
}

# Create the Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudwatch/${var.project_prefix}-cloudtrail"
  retention_in_days = var.default_log_retention_days
  tags              = var.tags
}

# Data for the Cloudwatch Role
data "aws_iam_policy_document" "cloudtrail" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.logging.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logging.arn}/prefix/AWSLogs/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:*"]
    }
  }
}

# Create the Cloudwatch AssumeRole
data "aws_iam_policy_document" "cloudtrail-assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

# Create the Cloudwatch Role Arn
resource "aws_iam_role" "cloudtrail" {
  name               = "${var.project_prefix}-cloudtrail"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail-assume.json
  tags               = var.tags
}

# Create the Trail
resource "aws_cloudtrail" "portfolio" {
  name                          = "${var.project_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.logging.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail.arn
  kms_key_id                 = data.aws_kms_alias.cloudtrail.id

  depends_on = [
    aws_s3_bucket.logging,
    aws_s3_bucket_policy.logging,
  ]

  tags = var.tags

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }
}

