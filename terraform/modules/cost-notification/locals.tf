locals {
  # Account & Region info
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  # DynamoDB
  dynamodb_table_name     = "${var.app_name}-settings"
  dynamodb_billing_mode   = "PAY_PER_REQUEST"
  dynamodb_read_capacity  = null
  dynamodb_write_capacity = null
  dynamodb_hash_key       = "type"
  dynamodb_hash_key_type  = "S"

  # ECR
  image_name           = "app/${var.app_name}"
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true

  # Lambda
  function_name        = var.app_name
  function_role_name   = "${var.app_name}-lambda-role"
  function_policy_name = "${var.app_name}-lambda-policy"
  function_log_format  = "JSON"
  cost_metrics_value   = "UnblendedCost"
  ephemeral_storage_size = 512
  line_api_url         = "https://api.line.me/v2/bot/message/push"

  # EventBridge Scheduler
  scheduler_name               = "${var.app_name}-scheduler"
  scheduler_role_name          = "${var.app_name}-scheduler-role"
  scheduler_policy_name        = "${var.app_name}-scheduler-policy"
  schedule_expression_tz       = "Asia/Tokyo"
  flexible_time_window         = "OFF"
  maximum_retry_attempts       = 0
  maximum_event_age_in_seconds = 60
}
