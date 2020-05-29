# Setup Cloudtrail so the project assets have visibility for troubleshooting and security review
resource "aws_cloudtrail" "portfolio" {
  name                          = "${var.bucket_prefix}-trail"
  s3_bucket_name                = "${aws_s3_bucket.logging.id}"
  include_global_service_events = true
  is_multi_region_trail         = true
  depends_on = ["aws_s3_bucket.logging","aws_s3_bucket_policy.logging"]

  tags = "${merge(map("Name","${var.bucket_prefix}-trail"), var.tags)}"

  event_selector {
    read_write_type   = "All"
#    include_management_events = true

    data_resource {
      type    = "AWS::S3::Object"
      values  = ["arn:aws:s3:::"]
    }
  }
}
