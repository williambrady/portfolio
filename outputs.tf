output "aws_s3_bucket_logging" {
  value = aws_s3_bucket.logging.id
}

output "aws_s3_bucket_dataset" {
  value = aws_s3_bucket.dataset.id
}

output "aws_s3_bucket_random" {
  value = aws_s3_bucket.george.id
}

output "aws_cloudtrail_portfolio" {
  value = aws_cloudtrail.portfolio.id
}

output "aws_iam_lambda_role" {
  value = aws_iam_role.lambda_access.arn
}

output "aws_api_endpoint" {
  value = aws_api_gateway_deployment.portfolio.invoke_url
}

