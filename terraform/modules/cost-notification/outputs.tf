output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.settings.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.settings.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.this.repository_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.this.arn
}

output "scheduler_name" {
  description = "EventBridge Scheduler name"
  value       = aws_scheduler_schedule.this.name
}
