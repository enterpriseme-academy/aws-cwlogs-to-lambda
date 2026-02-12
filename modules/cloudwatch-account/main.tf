# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days

  tags = var.tags
}

# IAM role for CloudWatch Logs to assume
resource "aws_iam_role" "cloudwatch_logs_role" {
  name = "${replace(var.log_group_name, "/", "-")}-subscription-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for CloudWatch Logs to invoke Lambda in another account
resource "aws_iam_role_policy" "cloudwatch_logs_policy" {
  name = "cloudwatch-logs-lambda-invoke-policy"
  role = aws_iam_role.cloudwatch_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = var.lambda_function_arn
      }
    ]
  })
}

# CloudWatch Logs Destination
resource "aws_cloudwatch_log_destination" "lambda_destination" {
  name       = "${replace(var.log_group_name, "/", "-")}-destination"
  role_arn   = aws_iam_role.cloudwatch_logs_role.arn
  target_arn = var.lambda_function_arn

  depends_on = [aws_iam_role_policy.cloudwatch_logs_policy]
}

# CloudWatch Logs Destination Policy (allows the log group to use the destination)
resource "aws_cloudwatch_log_destination_policy" "lambda_destination_policy" {
  destination_name = aws_cloudwatch_log_destination.lambda_destination.name
  access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        }
        Action = "logs:PutSubscriptionFilter"
        Resource = aws_cloudwatch_log_destination.lambda_destination.arn
      }
    ]
  })
}

# Data source to get current account ID
data "aws_caller_identity" "current" {}

# CloudWatch Logs Subscription Filter
resource "aws_cloudwatch_log_subscription_filter" "lambda_subscription" {
  name            = var.subscription_filter_name
  log_group_name  = aws_cloudwatch_log_group.app_logs.name
  filter_pattern  = var.filter_pattern
  destination_arn = aws_cloudwatch_log_destination.lambda_destination.arn

  depends_on = [
    aws_cloudwatch_log_destination_policy.lambda_destination_policy
  ]
}
