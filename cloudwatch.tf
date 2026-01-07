resource "aws_cloudwatch_log_group" "lambda_writer_logs" {
  name              = "/aws/lambda/${var.project_name}-writer"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda_stream_logs" {
  name              = "/aws/lambda/${var.project_name}-stream-processor"
  retention_in_days = 7

  tags = local.common_tags
}

resource "aws_cloudwatch_event_rule" "stream_trigger" {
  name                = "${var.project_name}-stream-trigger"
  description         = "Trigger stream processor every minute"
  schedule_expression = "rate(1 minute)"

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "stream_lambda" {
  rule      = aws_cloudwatch_event_rule.stream_trigger.name
  target_id = "StreamProcessorTarget"
  arn       = aws_lambda_function.stream_processor.arn
}