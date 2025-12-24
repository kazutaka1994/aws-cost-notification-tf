variable "schedule_expression" {
  description = "Cron expression for scheduler (environment-dependent)"
  type        = string
}

variable "app_name" {
  description = "Application name used for resource naming"
  type        = string
  default     = "cost-notification"
}

variable "scheduler_state" {
  description = "EventBridge Scheduler state (ENABLED or DISABLED)"
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.scheduler_state)
    error_message = "Scheduler state must be ENABLED or DISABLED."
  }
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 10

  validation {
    condition     = var.timeout >= 3 && var.timeout <= 900
    error_message = "Timeout must be between 3 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "function_log_retention_in_days" {
  description = "CloudWatch Log Group retention period in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.function_log_retention_in_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention period."
  }
}

variable "image_count" {
  description = "Number of ECR images to retain"
  type        = number
  default     = 3

  validation {
    condition     = var.image_count >= 1
    error_message = "Image count must be at least 1."
  }
}
