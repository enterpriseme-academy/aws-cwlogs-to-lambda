# Archive the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../lambda-code/index.py"
  output_path = "${path.module}/../../lambda-code/lambda_function.zip"
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function
resource "aws_lambda_function" "log_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
  timeout          = 60

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  tags = var.tags
}

# Lambda permission to allow CloudWatch Logs from Account B to invoke the function
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id   = "AllowExecutionFromCloudWatchLogs"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.log_processor.function_name
  principal      = "logs.amazonaws.com"
  source_account = var.cloudwatch_account_id
  source_arn     = var.cloudwatch_log_group_arn
}

# IAM role for CloudWatch Logs destination to invoke Lambda
resource "aws_iam_role" "destination_role" {
  name = "${var.lambda_function_name}-destination-role"

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

# IAM policy for destination role to invoke Lambda
resource "aws_iam_role_policy" "destination_policy" {
  name = "destination-lambda-invoke-policy"
  role = aws_iam_role.destination_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.log_processor.arn
      }
    ]
  })
}

# CloudWatch Logs Destination in Account A
resource "aws_cloudwatch_log_destination" "lambda_destination" {
  name       = "${var.lambda_function_name}-destination"
  role_arn   = aws_iam_role.destination_role.arn
  target_arn = aws_lambda_function.log_processor.arn

  depends_on = [aws_iam_role_policy.destination_policy]
}

# CloudWatch Logs Destination Policy (allows Account B to use the destination)
resource "aws_cloudwatch_log_destination_policy" "lambda_destination_policy" {
  destination_name = aws_cloudwatch_log_destination.lambda_destination.name
  access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.cloudwatch_account_id
        }
        Action   = "logs:PutSubscriptionFilter"
        Resource = aws_cloudwatch_log_destination.lambda_destination.arn
      }
    ]
  })
}
