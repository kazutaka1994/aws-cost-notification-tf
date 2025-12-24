# ==================================================
# Module: Cost Notification
# ==================================================
module "cost_notification" {
  source = "../../modules/cost-notification"

  # Required
  schedule_expression = var.schedule_expression

  # Optional (using defaults if not specified)
  app_name                       = var.app_name
  scheduler_state                = var.scheduler_state
  timeout                        = var.timeout
  memory_size                    = var.memory_size
  function_log_retention_in_days = var.function_log_retention_in_days
  image_count                    = var.image_count
}

# ==================================================
# Outputs
# ==================================================
output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.cost_notification.dynamodb_table_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.cost_notification.ecr_repository_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.cost_notification.lambda_function_name
}

output "scheduler_name" {
  description = "EventBridge Scheduler name"
  value       = module.cost_notification.scheduler_name
}
