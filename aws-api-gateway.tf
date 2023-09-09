resource "aws_api_gateway_rest_api" "portfolio" {
  name        = "Portfolio API"
  description = "Portfolio API for Car data"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags       = var.tags
  depends_on = [aws_lambda_function.portfolio]
}

resource "aws_api_gateway_stage" "portfolio" {
  depends_on           = [aws_api_gateway_deployment.portfolio]
  deployment_id        = aws_api_gateway_deployment.portfolio.id
  rest_api_id          = aws_api_gateway_rest_api.portfolio.id
  stage_name           = "cars"
  xray_tracing_enabled = true
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.portfolio.id
  parent_id   = aws_api_gateway_rest_api.portfolio.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.portfolio.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.portfolio.id
  stage_name  = aws_api_gateway_deployment.portfolio.stage_name
  method_path = "*/*"
  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

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

resource "aws_api_gateway_method_settings" "proxy_root" {
  rest_api_id = aws_api_gateway_rest_api.portfolio.id
  stage_name  = aws_api_gateway_deployment.portfolio.stage_name
  method_path = "*/*"
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
  stage_name  = "cars"
}

resource "aws_wafv2_web_acl" "portfolio" {
  name        = "portfolio"
  description = "portfolio"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "portfolio"
    sampled_requests_enabled   = true
  }
  depends_on = [
    aws_api_gateway_deployment.portfolio,
  ]
}