terraform {
  required_version = ">= 1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    region  = "ap-northeast-1"
    key     = "app/cost-notification.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region = "ap-northeast-1"
}