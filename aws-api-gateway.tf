# Buidl the API Gateway for the lambda function and ensure it meets CIS and AWS Standards.

# Define the API Gateway account.
resource "aws_api_gateway_account" "portfolio" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn
}

# Define the IAM Policy for the API Gateway to access CloudWatch.
data "aws_iam_policy_document" "apigw_cloudwatch" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]

    resources = ["*"]
  }
}

# Define the IAM Policy for the API Gateway to assume role.
data "aws_iam_policy_document" "apigw_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create the Cloudwatch IAM Role.
resource "aws_iam_role" "apigw_cloudwatch" {
  name               = "${var.project_prefix}-api_gateway_cloudwatch_role"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume_role.json
  tags               = var.tags
}

# Create the Cloudwatch Log Group for API Gateway events.
resource "aws_cloudwatch_log_group" "apigw_log_group" {
  name              = "${var.project_prefix}-api-gateway"
  retention_in_days = var.default_log_retention_days
  tags              = var.tags
}

# Create the IAM Role Policy for the API Gateway to access CloudWatch.
resource "aws_iam_role_policy" "apigw_cloudwatch" {
  name   = "${var.project_prefix}-api-gateway-cloudwatch"
  role   = aws_iam_role.apigw_cloudwatch.id
  policy = data.aws_iam_policy_document.apigw_cloudwatch.json
}

# Create the API Gateway.
resource "aws_api_gateway_rest_api" "portfolio" {
  name        = "${var.project_prefix} API"
  description = "${var.project_prefix} API Gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags       = var.tags
  depends_on = [aws_lambda_function.portfolio]
}

# Define the API Gateway Stage.
resource "aws_api_gateway_stage" "alpha" {
  depends_on    = [aws_api_gateway_deployment.portfolio]
  deployment_id = aws_api_gateway_deployment.portfolio.id
  rest_api_id   = aws_api_gateway_rest_api.portfolio.id
  stage_name    = "alpha"
}

# Define the API Gateway Resource.
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.portfolio.id
  parent_id   = aws_api_gateway_rest_api.portfolio.root_resource_id
  path_part   = "{proxy+}"
}

# Define the API Gateway Method.
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.portfolio.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  authorization = "NONE"
}

# Define the API Gateway Method Settings for default behavior.
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.portfolio.id
  stage_name  = aws_api_gateway_stage.alpha.stage_name
  method_path = "*/*"
  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

# Connect Lambda to API Gateway.
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.portfolio.id
  resource_id             = aws_api_gateway_method.proxy.resource_id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.portfolio.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.portfolio.id
  resource_id   = aws_api_gateway_rest_api.portfolio.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "root" {
  rest_api_id = aws_api_gateway_rest_api.portfolio.id
  stage_name  = aws_api_gateway_stage.alpha.stage_name
  method_path = "*/*"
  # method_path = aws_api_gateway_method.proxy_root.resource_id
  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id             = aws_api_gateway_rest_api.portfolio.id
  resource_id             = aws_api_gateway_method.proxy_root.resource_id
  http_method             = aws_api_gateway_method.proxy_root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.portfolio.invoke_arn
}

resource "aws_api_gateway_deployment" "portfolio" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]
  rest_api_id = aws_api_gateway_rest_api.portfolio.id
  lifecycle {
    create_before_destroy = true
  }
  # stage_name  = "alpha"
}
