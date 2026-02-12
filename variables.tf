variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "account_a_profile" {
  description = "AWS CLI profile for Account A (Lambda account)"
  type        = string
  default     = "account-a"
}

variable "account_b_profile" {
  description = "AWS CLI profile for Account B (CloudWatch account)"
  type        = string
  default     = "account-b"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "cloudwatch-logs-processor"
}

variable "log_group_name" {
  description = "Name of the CloudWatch Log Group"
  type        = string
  default     = "/aws/application/logs"
}

variable "retention_in_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 7
}

variable "subscription_filter_name" {
  description = "Name of the subscription filter"
  type        = string
  default     = "lambda-subscription-filter"
}

variable "filter_pattern" {
  description = "CloudWatch Logs filter pattern (empty string means all logs)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "CloudWatch-to-Lambda"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
