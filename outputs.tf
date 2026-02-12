output "account_a_id" {
  description = "Account A (Lambda) ID"
  value       = data.aws_caller_identity.account_a.account_id
}

output "account_b_id" {
  description = "Account B (CloudWatch) ID"
  value       = data.aws_caller_identity.account_b.account_id
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function in Account A"
  value       = module.lambda_account.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function in Account A"
  value       = module.lambda_account.lambda_function_name
}

output "log_group_name" {
  description = "Name of the CloudWatch Log Group in Account B"
  value       = module.cloudwatch_account.log_group_name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group in Account B"
  value       = module.cloudwatch_account.log_group_arn
}

output "subscription_filter_name" {
  description = "Name of the subscription filter in Account B"
  value       = module.cloudwatch_account.subscription_filter_name
}
