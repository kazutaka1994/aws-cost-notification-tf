variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "schedule_expression" {
  description = "Cron expression for scheduler (environment-dependent)"
  type        = string
}

# ==================================================
# Module Configuration
# ==================================================
variable "app_name" {
  description = "Application name used for resource naming"
  type        = string
  default     = "cost-notification"
}

variable "scheduler_state" {
  description = "EventBridge Scheduler state (ENABLED or DISABLED)"
  type        = string
  default     = "DISABLED"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "function_log_retention_in_days" {
  description = "CloudWatch Log Group retention period in days"
  type        = number
  default     = 30
}

variable "image_count" {
  description = "Number of ECR images to retain"
  type        = number
  default     = 3
}
