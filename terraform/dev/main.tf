resource "aws_dynamodb_table" "only_hash" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = local.dynamodb_hash_key

  attribute {
    name = local.dynamodb_hash_key
    type = local.dynamodb_hash_key_type
  }
}

data "aws_iam_policy_document" "default" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "default" {
  name               = local.function_role_name
  assume_role_policy = data.aws_iam_policy_document.default.json
}

resource "aws_iam_role_policy" "default" {
  name = local.function_policy_name
  role = aws_iam_role.default.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:${local.aws_region}:${local.account_id}:log-group:/aws/lambda/${local.function_name}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:GetItem"
        ],
        "Resource" : "arn:aws:dynamodb:${local.aws_region}:${local.account_id}:table/${local.dynamodb_table_name}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ce:GetCostAndUsage"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "log" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = local.log_retention_in_days
  # タグを追加したい場合はここに追加できます
  # tags = {
  #   Environment = "production"
  #   Application = "cost-notification"
  # }
}

resource "aws_lambda_function" "function" {
  function_name = local.function_name
  role          = aws_iam_role.default.arn

  // ZIPパッケージを使用するように変更
  filename         = "${path.module}/../../application/_lambda_zip/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../application/_lambda_zip/lambda_function.zip")
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12" // 適切なPythonランタイムバージョンに変更

  timeout     = local.timeout
  memory_size = local.memory_size

  ephemeral_storage {
    size = local.ephemeral_storage_size
  }

  logging_config {
    log_format = local.function_log_format
  }

  environment {
    variables = {
      COST_METRICS_VALUE = local.cost_metrics_value
      SETTINGS_TABLE     = local.dynamodb_table_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.log,
    aws_iam_role.default
  ]
}

// ECRモジュールは不要になるため、コメントアウトまたは削除
/*
module "ecr" {
  source               = "../modules/ecr/"
  image_name           = local.image_name
  image_tag_mutability = local.image_tag_mutability
  scan_on_push         = local.scan_on_push
  image_count          = local.image_count
}
*/

module "eb-scheduler" {
  source                       = "../modules/eb-scheduler-lambda/"
  scheduler_role_name          = local.scheduler_role_name
  schdeuler_policy_name        = local.schdeuler_policy_name
  scheduler_name               = local.scheduler_name
  scheduler_state              = local.scheduler_state
  schedule_expression          = local.schedule_expression
  schedule_expression_tz       = local.schedule_expression_tz
  flexible_time_window         = local.flexible_time_window
  scheduler_target_arn         = aws_lambda_function.function.arn
  maximum_retry_attempts       = local.maximum_retry_attempts
  maximum_event_age_in_seconds = local.maximum_event_age_in_seconds
}
