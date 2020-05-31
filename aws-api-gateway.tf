resource "aws_api_gateway_rest_api" "portfolio" {
  name        = "Portfolio API"
  description = "Portfolio API for Car data"
  endpoint_configuration {
    types     = ["REGIONAL"]
  }
  tags        = "${merge(map("Name","portfolio-lambda"), var.tags)}"
  depends_on  = ["aws_lambda_function.portfolio"]
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.portfolio.id}"
  parent_id   = "${aws_api_gateway_rest_api.portfolio.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.portfolio.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.portfolio.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.portfolio.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.portfolio.id}"
  resource_id   = "${aws_api_gateway_rest_api.portfolio.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
 }

 resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.portfolio.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.portfolio.invoke_arn}"
 }

resource "aws_api_gateway_deployment" "portfolio" {
  depends_on = ["aws_api_gateway_integration.lambda","aws_api_gateway_integration.lambda_root"]
  rest_api_id = "${aws_api_gateway_rest_api.portfolio.id}"
  stage_name  = "cars"
}
