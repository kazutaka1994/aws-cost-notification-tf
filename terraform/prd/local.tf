data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name

  # DynamoDB設定
  dynamodb_table_name    = "cost-notification-settings"
  dynamodb_hash_key      = "type"
  dynamodb_hash_key_type = "S"

  # Lambda関数設定
  function_role_name     = "cost-notification-lambda-role"
  function_policy_name   = "cost-notification-lambda-policy"
  function_name          = "cost-notification"
  timeout                = 10
  memory_size            = 128
  ephemeral_storage_size = 512
  function_log_format    = "JSON"
  cost_metrics_value     = "UnblendedCost"
  log_retention_in_days  = 30

  # スケジューラー設定
  scheduler_role_name          = "cost-notification-scheduler-role"
  schdeuler_policy_name        = "cost-notification-scheduler-policy"
  scheduler_name               = "cost-notification-scheduler"
  scheduler_state              = "ENABLED" # "DISABLED"への切り替えも可能
  schedule_expression          = "cron(10 12 ? * MON *)"
  schedule_expression_tz       = "Asia/Tokyo"
  flexible_time_window         = "OFF"
  maximum_retry_attempts       = 0
  maximum_event_age_in_seconds = 60
}