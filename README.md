# AWS CloudWatch Logs to Lambda - Cross-Account Setup

This Terraform configuration deploys a cross-account setup where CloudWatch Logs from one AWS account (Account B) are sent to a Lambda function in another AWS account (Account A).

## Architecture

```
┌─────────────────────────────────────────┐
│         Account A (Lambda)              │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Lambda Function                  │ │
│  │  - Receives CloudWatch Logs       │ │
│  │  - Prints/Processes log data      │ │
│  │                                   │ │
│  │  Lambda Permission:               │ │
│  │  - Allows CloudWatch Logs service │ │
│  └───────────────────────────────────┘ │
│                │                        │
│                ▼                        │
│  ┌───────────────────────────────────┐ │
│  │  CloudWatch Destination           │ │
│  │  - Receives from Account B        │ │
│  │  - Routes to Lambda               │ │
│  │                                   │ │
│  │  IAM Role:                        │ │
│  │  - Allows invoking Lambda         │ │
│  │                                   │ │
│  │  Destination Policy:              │ │
│  │  - Allows Account B access        │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
                    ▲
                    │ Cross-Account Subscription
                    │
┌─────────────────────────────────────────┐
│         Account B (CloudWatch)          │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  CloudWatch Log Group             │ │
│  │  - Stores application logs        │ │
│  └───────────────────────────────────┘ │
│                │                        │
│                ▼                        │
│  ┌───────────────────────────────────┐ │
│  │  Subscription Filter              │ │
│  │  - Filters log events             │ │
│  │  - Points to Destination in A     │ │
│  └───────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Components

### Account A (Lambda Account)
- **Lambda Function**: Python function that receives, decompresses, and prints CloudWatch Logs
- **Lambda IAM Role**: Allows Lambda to write to CloudWatch Logs for its own execution
- **Lambda Permission**: Allows CloudWatch Logs service to invoke the Lambda function
- **CloudWatch Destination**: Endpoint that receives log events from Account B and routes them to Lambda
- **Destination IAM Role**: Allows the destination to invoke the Lambda function
- **Destination Policy**: Grants Account B permission to send logs to this destination

### Account B (CloudWatch Account)
- **CloudWatch Log Group**: Stores application logs
- **Subscription Filter**: Filters and forwards log events to the destination in Account A

## Prerequisites

1. Two AWS accounts with appropriate permissions
2. Terraform >= 1.0 installed
3. AWS CLI configured with profiles or credentials for both accounts

## AWS Credentials Setup

You have two options for configuring AWS credentials:

### Option 1: AWS CLI Profiles (Recommended for local development)

Configure profiles in `~/.aws/credentials`:

```ini
[account-a]
aws_access_key_id = YOUR_ACCOUNT_A_ACCESS_KEY
aws_secret_access_key = YOUR_ACCOUNT_A_SECRET_KEY

[account-b]
aws_access_key_id = YOUR_ACCOUNT_B_ACCESS_KEY
aws_secret_access_key = YOUR_ACCOUNT_B_SECRET_KEY
```

Then in `~/.aws/config`:

```ini
[profile account-a]
region = us-east-1

[profile account-b]
region = us-east-1
```

### Option 2: Assume Role (Recommended for CI/CD)

Edit `providers.tf` and uncomment the assume_role blocks:

```hcl
provider "aws" {
  alias  = "account_a"
  region = var.aws_region
  
  assume_role {
    role_arn = "arn:aws:iam::ACCOUNT_A_ID:role/TerraformRole"
  }
}

provider "aws" {
  alias  = "account_b"
  region = var.aws_region
  
  assume_role {
    role_arn = "arn:aws:iam::ACCOUNT_B_ID:role/TerraformRole"
  }
}
```

## Usage

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd aws-cwlogs-to-lambda
   ```

2. **Create your terraform.tfvars file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars** with your configuration:
   ```hcl
   aws_region = "us-east-1"
   account_a_profile = "account-a"
   account_b_profile = "account-b"
   lambda_function_name = "cloudwatch-logs-processor"
   log_group_name = "/aws/application/logs"
   ```

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Review the execution plan**:
   ```bash
   terraform plan
   ```

6. **Apply the configuration**:
   ```bash
   terraform apply
   ```

7. **Verify the setup** by checking outputs:
   ```bash
   terraform output
   ```

## Testing the Setup

After deployment, you can test the setup by sending logs to the CloudWatch Log Group:

```bash
# Set your Account B profile
export AWS_PROFILE=account-b

# Send a test log message
aws logs put-log-events \
  --log-group-name "/aws/application/logs" \
  --log-stream-name "test-stream" \
  --log-events timestamp=$(date +%s000),message="Test log message from Account B"

# Note: You may need to create the log stream first:
aws logs create-log-stream \
  --log-group-name "/aws/application/logs" \
  --log-stream-name "test-stream"
```

Then check the Lambda function logs in Account A:

```bash
# Set your Account A profile
export AWS_PROFILE=account-a

# View Lambda logs
aws logs tail /aws/lambda/cloudwatch-logs-processor --follow
```

## Configuration Variables

| Variable                   | Description                      | Default                      |
| -------------------------- | -------------------------------- | ---------------------------- |
| `aws_region`               | AWS region for resources         | `us-east-1`                  |
| `account_a_profile`        | AWS CLI profile for Account A    | `account-a`                  |
| `account_b_profile`        | AWS CLI profile for Account B    | `account-b`                  |
| `lambda_function_name`     | Name of the Lambda function      | `cloudwatch-logs-processor`  |
| `log_group_name`           | Name of the CloudWatch Log Group | `/aws/application/logs`      |
| `retention_in_days`        | Number of days to retain logs    | `7`                          |
| `subscription_filter_name` | Name of the subscription filter  | `lambda-subscription-filter` |
| `filter_pattern`           | CloudWatch Logs filter pattern   | `""` (all logs)              |
| `tags`                     | Tags to apply to all resources   | See `variables.tf`           |

## Filter Patterns

The `filter_pattern` variable allows you to filter which logs are sent to Lambda. Examples:

- `""` - Send all logs (default)
- `"[ERROR]"` - Only logs containing "ERROR"
- `"{ $.level = "ERROR" }"` - Only logs with level field equal to ERROR (JSON logs)
- `"[time, request_id, event_type = ERROR, message]"` - Pattern matching specific fields

See [AWS CloudWatch Logs Filter Pattern Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html) for more details.

## Outputs

| Output                     | Description                                         |
| -------------------------- | --------------------------------------------------- |
| `account_a_id`             | Account A (Lambda) ID                               |
| `account_b_id`             | Account B (CloudWatch) ID                           |
| `lambda_function_arn`      | ARN of the Lambda function in Account A             |
| `lambda_function_name`     | Name of the Lambda function in Account A            |
| `log_group_name`           | Name of the CloudWatch Log Group in Account B       |
| `log_group_arn`            | ARN of the CloudWatch Log Group in Account B        |
| `subscription_filter_name` | Name of the subscription filter in Account B        |
| `destination_arn`          | ARN of the CloudWatch Logs Destination in Account A |

## Lambda Function

The Lambda function (`lambda-code/index.py`) is written in Python and:
1. Receives base64-encoded, gzip-compressed log data from CloudWatch Logs
2. Decodes and decompresses the data
3. Parses the JSON log structure
4. Prints log metadata (log group, stream, message type, etc.)
5. Prints individual log events with timestamps and messages

You can modify this function to:
- Send logs to external systems (Elasticsearch, Splunk, etc.)
- Transform or enrich log data
- Filter or aggregate logs
- Trigger alerts based on log content

## Security Considerations

1. **IAM Permissions**: The Lambda function has basic execution permissions. Adjust as needed for your use case.
2. **Cross-Account Access**: The Lambda permission is restricted to the specific CloudWatch account and log group.
3. **Secrets**: Never commit `terraform.tfvars` with real credentials. Use `.gitignore` to exclude it.
4. **Least Privilege**: Consider further restricting IAM policies based on your security requirements.

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

### Lambda is not being invoked

1. Check CloudWatch Logs subscription filter status in Account B
2. Verify Lambda permission allows invocation from CloudWatch Logs service
3. Check the destination IAM role in Account A has permission to invoke Lambda
4. Review the destination policy in Account A allows Account B to use the destination
5. Verify the subscription filter in Account B correctly references the destination ARN from Account A

### No logs appearing in Lambda

1. Ensure logs are being written to the CloudWatch Log Group in Account B
2. Check the subscription filter pattern matches your logs
3. Verify the subscription filter is active
4. Check Lambda function CloudWatch Logs for errors

### Permission denied errors

1. Verify AWS credentials are correctly configured for both accounts
2. Ensure IAM roles/users have necessary permissions
3. Check that account IDs are correct in the configuration

## References

- [AWS CloudWatch Logs Subscriptions](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Subscriptions.html)
- [AWS Lambda Permissions](https://docs.aws.amazon.com/lambda/latest/dg/lambda-permissions.html)
- [Cross-Account CloudWatch Logs Subscriptions](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CrossAccountSubscriptions.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

This project is provided as-is for educational and reference purposes.
