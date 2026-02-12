output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.log_processor.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.log_processor.function_name
}

output "destination_arn" {
  description = "ARN of the CloudWatch Logs Destination"
  value       = aws_cloudwatch_log_destination.lambda_destination.arn
}
