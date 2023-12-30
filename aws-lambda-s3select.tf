# Lambda function access

# Setup the data block to define IAM policy for Lambda AssumeRole
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Setup the data block to define IAM policy for Lambda S3 Read and SSM Read
data "aws_iam_policy_document" "lambda_read" {
  statement {
    actions = [
      "logs:CreateLogGroup",
    ]
    resources = [
      "arn:aws:logs:us-east-1:918573727633:*",
    ]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:us-east-1:918573727633:log-group:/aws/lambda/${var.project_prefix}:*",
    ]
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "${aws_s3_bucket.dataset.arn}",
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.dataset.arn}/*",
    ]
  }
  statement {
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      aws_ssm_parameter.s3_bucket_name.arn
    ]
  }
}

# Create an Instance Role to allow the Lambda instance to AssumeRole.
resource "aws_iam_role" "lambda_access" {
  name               = "${var.project_prefix}-lambda_access-role"
  path               = "/service-role/"
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Create S3 policy for Lambda
resource "aws_iam_policy" "lambda_read" {
  name   = "${var.project_prefix}-lambda_read-policy"
  tags   = var.tags
  policy = data.aws_iam_policy_document.lambda_read.json
}

# Create the instance profile for Lambda
resource "aws_iam_instance_profile" "lambda_instance_profile" {
  name = "${var.project_prefix}-lambda_instance_profile"
  role = aws_iam_role.lambda_access.name
  depends_on = [
    aws_iam_role.lambda_access,
    aws_iam_policy.lambda_read,
  ]
}

# Attach the Policy to the Instance Role
resource "aws_iam_role_policy_attachment" "lambda_read" {
  role       = aws_iam_role.lambda_access.name
  policy_arn = aws_iam_policy.lambda_read.arn
  depends_on = [aws_iam_policy.lambda_read]
}

# Lambda Content
resource "aws_lambda_function" "portfolio" {
  s3_bucket        = aws_s3_bucket.dataset.id
  s3_key           = "lambda_function.zip"
  function_name    = var.project_prefix
  memory_size      = 192
  role             = aws_iam_role.lambda_access.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = base64sha256("aws-lambda-${var.project_prefix}-payload.zip")
  tags             = var.tags
  depends_on = [
    aws_iam_instance_profile.lambda_instance_profile,
    aws_s3_object.lambda_function,
    aws_s3_object.dataset,
    aws_s3_object.lambda_function,
    aws_s3_object.og_dataset,
  ]
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.portfolio.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.portfolio.execution_arn}/*/*"
}

# Create SSM Stored Parameter for target S3 bucket name.
resource "aws_ssm_parameter" "s3_bucket_name" {
  name  = "/${var.project_prefix}/s3_bucket_name"
  type  = "String"
  value = aws_s3_bucket.dataset.id
  tags  = var.tags
}

# Log the lambda execution to Cloudwatch
resource "aws_cloudwatch_log_group" "portfolio" {
  name              = "/aws/lambda/${var.project_prefix}"
  retention_in_days = var.default_log_retention_days
  tags              = var.tags
}
