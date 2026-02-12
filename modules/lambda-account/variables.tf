variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "cloudwatch-logs-processor"
}

variable "cloudwatch_account_id" {
  description = "AWS Account ID of the CloudWatch Logs account (Account B)"
  type        = string
}

variable "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group in Account B"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
