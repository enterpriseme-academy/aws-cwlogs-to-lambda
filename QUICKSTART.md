# Quick Start Guide

This guide will help you deploy the cross-account CloudWatch Logs to Lambda setup in under 10 minutes.

## Prerequisites Checklist

- [ ] Two AWS accounts (Account A and Account B)
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed
- [ ] Appropriate IAM permissions in both accounts

## 5-Step Quick Setup

### Step 1: Configure AWS Credentials

Choose one of the following methods:

**Method A - AWS CLI Profiles** (Recommended for getting started)

```bash
# Configure Account A profile
aws configure --profile account-a
# Enter: Access Key ID, Secret Access Key, Region (e.g., us-east-1)

# Configure Account B profile
aws configure --profile account-b
# Enter: Access Key ID, Secret Access Key, Region (e.g., us-east-1)

# Test the profiles
aws sts get-caller-identity --profile account-a
aws sts get-caller-identity --profile account-b
```

**Method B - Assume Role** (For production/CI-CD)

See the "Option 2: Assume Role" section in README.md

### Step 2: Create Configuration File

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the configuration (optional - defaults should work)
nano terraform.tfvars  # or use your preferred editor
```

**Minimum Configuration** (if using default profile names):
```hcl
aws_region = "us-east-1"
account_a_profile = "account-a"
account_b_profile = "account-b"
```

### Step 3: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
...
Terraform has been successfully initialized!
```

### Step 4: Deploy the Infrastructure

```bash
# Review what will be created
terraform plan

# Deploy (you'll be prompted to confirm)
terraform apply

# Or auto-approve to skip confirmation
terraform apply -auto-approve
```

**What gets created:**
- Account A: 1 Lambda function, 1 IAM role, 1 Lambda permission
- Account B: 1 Log group, 1 IAM role, 1 Destination, 1 Subscription filter

### Step 5: Test the Setup

```bash
# Create a log stream in Account B
aws logs create-log-stream \
  --profile account-b \
  --log-group-name "/aws/application/logs" \
  --log-stream-name "test-stream"

# Send a test log message
aws logs put-log-events \
  --profile account-b \
  --log-group-name "/aws/application/logs" \
  --log-stream-name "test-stream" \
  --log-events timestamp=$(date +%s000),message="Hello from Account B!"

# Wait a few seconds, then check Lambda logs in Account A
aws logs tail /aws/lambda/cloudwatch-logs-processor \
  --profile account-a \
  --follow
```

**Expected result:** You should see the log message processed and printed by the Lambda function.

## Troubleshooting Quick Fixes

### "Error: No valid credential sources found"
```bash
# Check your AWS credentials
aws configure list --profile account-a
aws configure list --profile account-b
```

### "Error: AccessDenied"
Make sure your AWS credentials have these minimum permissions:
- Account A: Lambda, IAM, CloudWatch Logs (for Lambda logs)
- Account B: CloudWatch Logs, IAM

### "Lambda function not being invoked"
```bash
# Check subscription filter status
aws logs describe-subscription-filters \
  --profile account-b \
  --log-group-name "/aws/application/logs"

# Check Lambda permissions
aws lambda get-policy \
  --profile account-a \
  --function-name cloudwatch-logs-processor
```

### "Logs not appearing"
Wait 30-60 seconds after sending logs - there can be a slight delay in processing.

## Common Customizations

### Change Lambda Function Name
```hcl
# In terraform.tfvars
lambda_function_name = "my-custom-log-processor"
```

### Change Log Group Name
```hcl
# In terraform.tfvars
log_group_name = "/aws/my-app/logs"
```

### Filter Only ERROR Logs
```hcl
# In terraform.tfvars
filter_pattern = "[ERROR]"
```

### Change Region
```hcl
# In terraform.tfvars
aws_region = "eu-west-1"
```

After making changes:
```bash
terraform apply
```

## Clean Up

To remove all resources:
```bash
terraform destroy
```

## Next Steps

- Modify `lambda-code/index.py` to customize log processing
- Add additional IAM permissions if Lambda needs to access other AWS services
- Set up CloudWatch alarms for Lambda errors
- Configure additional log groups to send to the same Lambda

## Getting Help

1. Check the full [README.md](README.md) for detailed documentation
2. Review [DEPLOYMENT.md](DEPLOYMENT.md) for architecture details
3. Check [AWS CloudWatch Logs Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
4. Review Terraform outputs: `terraform output`

## Quick Reference Commands

```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output

# Destroy all resources
terraform destroy

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Check Lambda logs (Account A)
aws logs tail /aws/lambda/cloudwatch-logs-processor --profile account-a --follow

# Send test log (Account B)
aws logs put-log-events \
  --profile account-b \
  --log-group-name "/aws/application/logs" \
  --log-stream-name "test-stream" \
  --log-events timestamp=$(date +%s000),message="Test message"
```
