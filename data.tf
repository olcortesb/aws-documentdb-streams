data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "archive_file" "lambda_writer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/writer"
  output_path = "${path.module}/lambda_writer.zip"
}

data "archive_file" "lambda_stream_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/stream-processor"
  output_path = "${path.module}/lambda_stream_processor.zip"
}