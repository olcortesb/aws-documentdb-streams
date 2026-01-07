resource "aws_lambda_function" "writer" {
  filename         = data.archive_file.lambda_writer_zip.output_path
  function_name    = "${var.project_name}-writer"
  role            = aws_iam_role.lambda_writer_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_writer_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DOCDB_URI = local.docdb_uri
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_writer_basic,
    aws_cloudwatch_log_group.lambda_writer_logs,
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-writer"
  })
}

resource "aws_lambda_function" "stream_processor" {
  filename         = data.archive_file.lambda_stream_zip.output_path
  function_name    = "${var.project_name}-stream-processor"
  role            = aws_iam_role.lambda_stream_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_stream_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 300

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DOCDB_URI = local.docdb_uri
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_stream_basic,
    aws_cloudwatch_log_group.lambda_stream_logs,
  ]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-stream-processor"
  })
}

resource "aws_lambda_permission" "api_gateway_writer" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.writer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stream_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stream_trigger.arn
}