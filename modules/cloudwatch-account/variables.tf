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

variable "destination_arn" {
  description = "ARN of the CloudWatch Logs destination in the Lambda account"
  type        = string
}

variable "subscription_filter_name" {
  description = "Name of the subscription filter"
  type        = string
  default     = "lambda-subscription-filter"
}

variable "filter_pattern" {
  description = "CloudWatch Logs filter pattern"
  type        = string
  default     = "" # Empty string means all logs
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
