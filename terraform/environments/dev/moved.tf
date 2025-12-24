# ==================================================
# State Migration (moved blocks)
# ==================================================
# These moved blocks handle the migration from the old structure
# (resources defined directly in terraform/dev/) to the new modular structure
# (resources defined in modules/cost-notification/)
#
# Once migration is complete and verified, this file can be safely deleted.

# DynamoDB
moved {
  from = aws_dynamodb_table.settings
  to   = module.cost_notification.aws_dynamodb_table.settings
}

# ECR
moved {
  from = aws_ecr_repository.this
  to   = module.cost_notification.aws_ecr_repository.this
}

moved {
  from = aws_ecr_lifecycle_policy.this
  to   = module.cost_notification.aws_ecr_lifecycle_policy.this
}

moved {
  from = aws_ecr_repository_policy.this
  to   = module.cost_notification.aws_ecr_repository_policy.this
}

# Lambda
moved {
  from = aws_iam_role.lambda
  to   = module.cost_notification.aws_iam_role.lambda
}

moved {
  from = aws_iam_role_policy.lambda
  to   = module.cost_notification.aws_iam_role_policy.lambda
}

moved {
  from = aws_cloudwatch_log_group.lambda
  to   = module.cost_notification.aws_cloudwatch_log_group.lambda
}

moved {
  from = aws_lambda_function.this
  to   = module.cost_notification.aws_lambda_function.this
}

# EventBridge Scheduler
moved {
  from = aws_iam_role.scheduler
  to   = module.cost_notification.aws_iam_role.scheduler
}

moved {
  from = aws_iam_role_policy.scheduler
  to   = module.cost_notification.aws_iam_role_policy.scheduler
}

moved {
  from = aws_scheduler_schedule.this
  to   = module.cost_notification.aws_scheduler_schedule.this
}
