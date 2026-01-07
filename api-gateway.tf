resource "aws_api_gateway_rest_api" "main" {
  name = "${var.project_name}-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.common_tags
}

resource "aws_api_gateway_resource" "writer" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "write"
}

resource "aws_api_gateway_method" "writer_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.writer.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "writer_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.writer.id
  http_method = aws_api_gateway_method.writer_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.writer.invoke_arn
}

resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.writer_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  tags = local.common_tags
}