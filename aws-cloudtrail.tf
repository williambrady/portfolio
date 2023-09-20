# Setup Cloudtrail so the project assets have visibility for troubleshooting and security review

# Create the Cloudwatch Log Group
# Create the Cloudwatch Role Arn
# Identify the KMS Key

# Create the Trail
resource "aws_cloudtrail" "portfolio" {
  name                          = "${var.project_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.logging.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation = true
  enable_logging                = true
  cloud_watch_logs_group_arn = ""
  cloud_watch_logs_role_arn  = ""
  kms_key_id = ""

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

