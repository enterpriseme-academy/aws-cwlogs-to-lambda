# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days

  tags = var.tags
}

# CloudWatch Logs Subscription Filter
resource "aws_cloudwatch_log_subscription_filter" "lambda_subscription" {
  name            = var.subscription_filter_name
  log_group_name  = aws_cloudwatch_log_group.app_logs.name
  filter_pattern  = var.filter_pattern
  destination_arn = var.destination_arn
}
