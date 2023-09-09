# IAM Role

# Create an Instance Role to allow the Lambda instance to AssumeRole.
resource "aws_iam_role" "lambda_s3_read" {
  name               = "${var.project_prefix}-lambda_s3_read-role"
  path               = "/service-role/"
  tags               = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid" : ""
    }
  ]
}
EOF

}

# Create a Read-Only S3 policy to allow the lambda instance to read the S3 Bucket
resource "aws_iam_policy" "lambda_s3_read" {
  name   = "${var.project_prefix}-lambda_s3_read-policy"
  tags   = var.tags
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "logs:CreateLogGroup",
        "Resource": "arn:aws:logs:us-east-1:918573727633:*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": [
            "arn:aws:logs:us-east-1:918573727633:log-group:/aws/lambda:*"
        ]
    },
    {
        "Action": ["s3:ListBucket"],
        "Effect": "Allow",
        "Resource": ["${aws_s3_bucket.dataset.arn}"]
    },
    {
        "Action": ["s3:GetObject"],
        "Effect": "Allow",
        "Resource": ["${aws_s3_bucket.dataset.arn}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_s3_read" {
  role       = aws_iam_role.lambda_s3_read.name
  policy_arn = aws_iam_policy.lambda_s3_read.arn
  depends_on = [aws_iam_policy.lambda_s3_read]
}

#Attach the Policy to the Instance Role
resource "aws_iam_instance_profile" "lambda_s3_read" {
  name = "${var.project_prefix}-lambda_s3_read-profile"
  role = aws_iam_role.lambda_s3_read.name
  depends_on = [
    aws_iam_role.lambda_s3_read,
    aws_iam_policy.lambda_s3_read,
  ]
}

# Lambda Content
resource "aws_lambda_function" "portfolio" {
  # filename = "aws-lambda-portfolio-payload.zip"
  s3_bucket        = aws_s3_bucket.dataset.id
  s3_key           = "lambda_function.zip"
  function_name    = "portfolio-cars"
  memory_size      = 192
  role             = aws_iam_role.lambda_s3_read.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = base64sha256("aws-lambda-portfolio-payload.zip")
  tags             = var.tags
  depends_on = [
    aws_iam_instance_profile.lambda_s3_read,
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

