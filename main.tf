# Deploy Lambda function in Account A
module "lambda_account" {
  source = "./modules/lambda-account"

  providers = {
    aws = aws.account_a
  }

  lambda_function_name    = var.lambda_function_name
  cloudwatch_account_id   = data.aws_caller_identity.account_b.account_id
  cloudwatch_log_group_arn = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.account_b.account_id}:log-group:${var.log_group_name}:*"
  tags                    = var.tags
}

# Deploy CloudWatch Log Group and subscription in Account B
module "cloudwatch_account" {
  source = "./modules/cloudwatch-account"

  providers = {
    aws = aws.account_b
  }

  log_group_name           = var.log_group_name
  retention_in_days        = var.retention_in_days
  lambda_function_arn      = module.lambda_account.lambda_function_arn
  lambda_account_id        = data.aws_caller_identity.account_a.account_id
  subscription_filter_name = var.subscription_filter_name
  filter_pattern           = var.filter_pattern
  tags                     = var.tags

  depends_on = [module.lambda_account]
}
