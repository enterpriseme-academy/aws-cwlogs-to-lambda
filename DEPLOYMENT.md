# Deployment Flow

## Step-by-Step Deployment Process

### 1. Account A - Lambda Deployment
When you run `terraform apply`, Terraform first deploys resources in Account A:

1. **Lambda IAM Role** (`aws_iam_role.lambda_role`)
   - Creates an IAM role that Lambda can assume
   - Allows Lambda service to assume this role

2. **Lambda Policy Attachment** (`aws_iam_role_policy_attachment.lambda_basic_execution`)
   - Attaches AWS managed policy for basic Lambda execution
   - Allows Lambda to write logs to CloudWatch Logs

3. **Lambda Function** (`aws_lambda_function.log_processor`)
   - Packages the Python code into a ZIP file
   - Creates the Lambda function with the code
   - Configures handler, runtime (Python 3.9), and timeout

4. **Lambda Permission** (`aws_lambda_permission.allow_cloudwatch`)
   - Grants CloudWatch Logs service permission to invoke this Lambda
   - Allows cross-account invocation from Account B

5. **Destination IAM Role** (`aws_iam_role.cloudwatch_logs_role`)
   - Creates an IAM role for CloudWatch Logs Destination
   - Allows CloudWatch Logs service to assume this role

6. **Destination IAM Policy** (`aws_iam_role_policy.cloudwatch_logs_policy`)
   - Grants permission to invoke the Lambda function
   - Attached to the destination IAM role

7. **CloudWatch Destination** (`aws_cloudwatch_log_destination.lambda_destination`)
   - Creates a destination that routes log events to the Lambda function
   - Uses the IAM role to invoke Lambda
   - **Critical**: Must be in the same account as the Lambda function

8. **Destination Policy** (`aws_cloudwatch_log_destination_policy.lambda_destination_policy`)
   - Grants Account B permission to use this destination
   - Allows PutSubscriptionFilter action from Account B

### 2. Account B - CloudWatch Deployment
After Account A resources are created, Terraform deploys resources in Account B:

1. **CloudWatch Log Group** (`aws_cloudwatch_log_group.app_logs`)
   - Creates a log group to store application logs
   - Sets retention period

2. **Subscription Filter** (`aws_cloudwatch_log_subscription_filter.lambda_subscription`)
   - Creates a subscription filter on the log group
   - Filters log events based on the pattern
   - References the destination in Account A
   - Sends matching events cross-account to the destination

## Data Flow

```
Application
    │
    ├─> Write logs
    │
    ▼
CloudWatch Log Group (Account B)
    │
    ├─> Filter logs (Subscription Filter)
    │
    ├─> Cross-Account Call
    │
    ▼
CloudWatch Destination (Account A)
    │
    ├─> Assume IAM Role (Account A)
    │
    ├─> Invoke Lambda
    │
    ▼
Lambda Function (Account A)
    │
    ├─> Receive compressed logs
    │
    ├─> Decompress & Parse
    │
    ├─> Print to Lambda CloudWatch Logs
    │
    ▼
Lambda CloudWatch Logs (Account A)
```

## Key Terraform Concepts Used

### 1. Provider Aliases
- Allows working with multiple AWS accounts in the same configuration
- Each module specifies which provider to use via the `providers` block

### 2. Module Dependencies
- `depends_on = [module.lambda_account]` ensures Lambda is created before CloudWatch resources
- Terraform automatically handles dependencies between resources within modules

### 3. Data Sources
- `data.aws_caller_identity` retrieves the AWS account ID dynamically
- Used to construct ARNs and set permissions correctly

### 4. Resource Dependencies
- `depends_on` explicitly defines dependencies
- Terraform also infers dependencies from resource references

## Security Considerations

### Cross-Account Permissions
1. **Lambda Permission**: Lambda explicitly allows invocation from CloudWatch Logs service
2. **Destination IAM Role**: The destination in Account A assumes an IAM role to invoke Lambda (same account)
3. **Destination Policy**: Controls which accounts can create subscription filters to the destination (Account B)

### Least Privilege
- Lambda only has basic execution permissions
- Destination IAM role only has permission to invoke the specific Lambda function
- Destination policy only allows Account B to use the destination
- No wildcard permissions granted

### Key Architectural Point
**The CloudWatch Logs Destination must be in the same AWS account as the Lambda function.**
This is an AWS requirement - the destination and its target (Lambda) cannot be in different accounts.
The cross-account boundary is between:
- Account B's subscription filter → Account A's destination

## Customization Points

### Lambda Function
- Modify `lambda-code/index.py` to change log processing logic
- Can send logs to external systems, databases, etc.

### Filter Pattern
- Change `filter_pattern` variable to filter specific log events
- Examples:
  - `""` - All logs
  - `"[ERROR]"` - Only ERROR logs
  - `"{ $.level = "ERROR" }"` - JSON logs with level=ERROR

### Tags
- Customize `tags` variable to add metadata to all resources
- Helps with cost tracking, organization, and automation
