resource "aws_s3_bucket" "dataset" {
  depends_on    = [aws_s3_bucket.logging]
  bucket        = "${var.project_prefix}-${var.aws_account_id}-${var.aws_region}-dataset"
  force_destroy = true
  # logging {
  #   target_bucket = aws_s3_bucket.logging.id
  #   target_prefix = "s3-logs/${var.project_prefix}-${var.aws_account_id}-${var.aws_region}-dataset"
  # }
  provisioner "local-exec" {
    command = "python3 build.py ${var.infile}"
  }
  tags = var.tags
}

resource "aws_s3_bucket_logging" "dataset" {
  bucket        = aws_s3_bucket.dataset.id
  target_bucket = aws_s3_bucket.logging.id
  target_prefix = "s3-logs/${var.project_prefix}-${var.aws_account_id}-${var.aws_region}-dataset"
}

resource "aws_s3_bucket_versioning" "dataset" {
  bucket = aws_s3_bucket.dataset.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block Public Access to the bucket as it should never be needed.
resource "aws_s3_bucket_public_access_block" "dataset" {
  bucket                  = aws_s3_bucket.dataset.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload indexed_dataset.csv to the bucket for accessibility.
resource "aws_s3_object" "dataset" {
  depends_on = [aws_s3_bucket.dataset]
  bucket     = aws_s3_bucket.dataset.id
  key        = "indexed_dataset.csv"
  source     = "./indexed_dataset.csv"
}

# Upload the lambda function.
resource "aws_s3_object" "lambda_function" {
  depends_on = [aws_s3_bucket.dataset]
  bucket     = aws_s3_bucket.dataset.id
  key        = "lambda_function.zip"
  source     = "./lambda_function.zip"
  tags       = var.tags
}

# Upload original dataset.csv to the bucket for accessibility.
resource "aws_s3_object" "og_dataset" {
  depends_on = [aws_s3_bucket.dataset]
  bucket     = aws_s3_bucket.dataset.id
  key        = var.infile
  source     = "./${var.infile}"
  tags       = var.tags
}