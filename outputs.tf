output "docdb_cluster_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.main.endpoint
}

output "docdb_cluster_port" {
  description = "DocumentDB cluster port"
  value       = aws_docdb_cluster.main.port
}

output "api_gateway_url" {
  description = "API Gateway URL para probar la Lambda writer"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}/write"
}

output "lambda_writer_function_name" {
  description = "Nombre de la función Lambda writer"
  value       = aws_lambda_function.writer.function_name
}

output "lambda_stream_processor_function_name" {
  description = "Nombre de la función Lambda stream processor"
  value       = aws_lambda_function.stream_processor.function_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}