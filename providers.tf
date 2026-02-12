terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Provider for Account A (Lambda Account)
provider "aws" {
  alias  = "account_a"
  region = var.aws_region

  # Configure credentials for Account A
  # Option 1: Using profile
  profile = var.account_a_profile

  # Option 2: Using assume role (uncomment and configure if needed)
  # assume_role {
  #   role_arn = "arn:aws:iam::ACCOUNT_A_ID:role/TerraformRole"
  # }
}

# Provider for Account B (CloudWatch Account)
provider "aws" {
  alias  = "account_b"
  region = var.aws_region

  # Configure credentials for Account B
  # Option 1: Using profile
  profile = var.account_b_profile

  # Option 2: Using assume role (uncomment and configure if needed)
  # assume_role {
  #   role_arn = "arn:aws:iam::ACCOUNT_B_ID:role/TerraformRole"
  # }
}

# Data source to get Account A ID
data "aws_caller_identity" "account_a" {
  provider = aws.account_a
}

# Data source to get Account B ID
data "aws_caller_identity" "account_b" {
  provider = aws.account_b
}
