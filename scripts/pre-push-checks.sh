#!/bin/bash
# pre-push-checks.sh
# Script to automate various checks before pushing code to GitHub

set -e  # Exit immediately if a command exits with a non-zero status

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "============================================"
echo "      Starting pre-push checks"
echo "============================================"

# Check if required tools are installed
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "Error: $1 is not installed"
    echo "Installation method: $2"
    exit 1
  fi
}

check_command gitleaks "brew install gitleaks"
check_command tflint "brew install tflint"
check_command trivy "brew install trivy"
check_command terraform "brew install terraform"

# 1. Check for sensitive information using gitleaks
echo "🔎 Running sensitive information scan with gitleaks..."
gitleaks detect --verbose

# 2. Check Terraform formatting
echo "📝 Running Terraform format check..."

# dev directory
if [ -d terraform/dev ]; then
  echo "Checking format for terraform/dev..."
  terraform fmt -check -recursive terraform/dev
  terraform fmt -recursive terraform/dev
fi

# prd directory
if [ -d terraform/prd ]; then
  echo "Checking format for terraform/prd..."
  terraform fmt -check -recursive terraform/prd
  terraform fmt -recursive terraform/prd
fi

# modules directory
if [ -d terraform/modules ]; then
  echo "Checking format for terraform/modules..."
  terraform fmt -check -recursive terraform/modules
  terraform fmt -recursive terraform/modules
fi

# 3. Static analysis of Terraform code with tflint
echo "📊 Running Terraform static analysis with tflint..."

if [ -d terraform/dev ]; then
  echo "Linting terraform/dev..."
  cd terraform/dev
  tflint
  cd "$REPO_ROOT"
fi

if [ -d terraform/prd ]; then
  echo "Linting terraform/prd..."
  cd terraform/prd
  tflint
  cd "$REPO_ROOT"
fi

if [ -d terraform/modules ]; then
  echo "Linting terraform/modules..."
  cd terraform/modules
  tflint
  cd "$REPO_ROOT"
fi

# 4. Security check with trivy
echo "🔒 Running security scan with trivy..."
trivy config --severity HIGH terraform/

echo "============================================"
echo "      All checks completed successfully 🎉"
echo "============================================"