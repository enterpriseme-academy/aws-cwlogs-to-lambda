output "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.app_logs.arn
}

output "subscription_filter_name" {
  description = "Name of the subscription filter"
  value       = aws_cloudwatch_log_subscription_filter.lambda_subscription.name
}
