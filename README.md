# AWS Cost Notification

A project to build an AWS cost notification system using Terraform.

## Overview

This project creates a system that regularly retrieves AWS cost information and sends notifications based on specified conditions. Infrastructure is defined as code using Terraform.

## Key Features

- Regularly fetches cost information using the AWS Cost Explorer API
- Notification functionality based on configured thresholds
- Sends notifications via LINE messaging

## System Components

- **Lambda Function**: Retrieves and processes cost information
- **DynamoDB**: Stores configuration information including LINE tokens
- **EventBridge Scheduler**: Manages periodic execution schedule

## Setup Instructions

### Prerequisites

- AWS CLI configured
- Terraform 1.11.4 or higher
- Python 3.12 or higher
- S3 bucket for Terraform state

### Terraform Configuration

This project uses the following Terraform configuration:

- **Required Terraform Version**: 1.11.4 or higher
- **AWS Provider Version**: ~> 5.0
- **Remote State**: Stored in S3 bucket
  - Region: ap-northeast-1
  - Key: app/cost-notification.tfstate
  - Encryption: Enabled

### Deployment Steps

1. Select the environment you want to deploy to (dev or prd)
   ```shell
   # For development environment
   cd terraform/dev
   
   # For production environment
   cd terraform/prd
   ```

2. Create ZIP package for Lambda
   ```shell
   cd application/lambda_zip
   ./build.sh
   ```

3. Initialize Terraform with your S3 bucket for state storage
   ```shell
   # Make sure you're in the appropriate environment directory (terraform/dev or terraform/prd)
   terraform init -backend-config="bucket=YOUR_S3_BUCKET_NAME"
   ```

4. Deploy with Terraform
   ```shell
   terraform plan
   terraform apply
   ```

## Configuration

You can configure cost notification settings in the environment-specific `local.tf` file:

- Development environment: `terraform/dev/local.tf`
- Production environment: `terraform/prd/local.tf`

Each environment can have its own configuration settings, such as notification thresholds, scheduling frequency, and resource naming.

## Architecture

The Lambda function runs on a schedule defined by EventBridge Scheduler. It retrieves cost data from AWS Cost Explorer, checks against configured thresholds, and sends notifications via LINE if conditions are met.

## Multiple Environments

This project is structured to support multiple deployment environments:

- **Development (dev)**: Used for testing and development purposes
- **Production (prd)**: The live environment for actual cost monitoring

Each environment has its own Terraform configuration, allowing for isolated resources and different settings between environments.

## Development

To modify the Lambda function code:
1. Edit the files in `application/codes/lambda_function.py`
2. Run the build script to create a new ZIP package
3. Apply the changes with Terraform in the desired environment

## Development Workflow

### Pre-Push Checks

This project includes automated pre-push checks to ensure code quality and security before pushing to GitHub. The checks are implemented in `scripts/pre-push-checks.sh` and include:

1. **Sensitive Information Detection**: Uses `gitleaks` to scan for credentials or other sensitive data
2. **Terraform Format Check**: Ensures Terraform code follows standard formatting conventions
3. **Terraform Linting**: Performs static analysis on Terraform code using `tflint`  
4. **Security Scanning**: Uses `trivy` to check for HIGH severity security issues

#### Setting up Pre-Push Hooks

The pre-push checks can be configured as Git hooks:

```shell
# Create Git hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
exec "$(git rev-parse --show-toplevel)/scripts/pre-push-checks.sh"
EOF

# Make hook executable
chmod +x .git/hooks/pre-push
```

#### Running Checks Manually

You can also run the checks manually:

```shell
./scripts/pre-push-checks.sh
```

#### Required Tools

The pre-push checks require the following tools:

- `gitleaks`: For sensitive information detection (`brew install gitleaks`)
- `tflint`: For Terraform linting (`brew install tflint`)
- `trivy`: For security scanning (`brew install trivy`)
- `terraform`: For formatting checks (`brew install terraform`)
