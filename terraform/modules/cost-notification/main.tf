# ==================================================
# Data Sources
# ==================================================
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ==================================================
# DynamoDB Table
# ==================================================
resource "aws_dynamodb_table" "settings" {
  name           = local.dynamodb_table_name
  billing_mode   = local.dynamodb_billing_mode
  read_capacity  = local.dynamodb_read_capacity
  write_capacity = local.dynamodb_write_capacity
  hash_key       = local.dynamodb_hash_key

  attribute {
    name = local.dynamodb_hash_key
    type = local.dynamodb_hash_key_type
  }
}

# ==================================================
# ECR Repository
# ==================================================
resource "aws_ecr_repository" "this" {
  name                 = local.image_name
  image_tag_mutability = local.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = local.scan_on_push
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  policy = jsonencode(
    {
      rules = [
        {
          action = {
            type = "expire"
          }
          description  = "Expire images"
          rulePriority = 1
          selection = {
            countNumber = var.image_count
            countType   = "imageCountMoreThan"
            tagStatus   = "any"
          }
        },
      ]
    }
  )
  repository = aws_ecr_repository.this.name
}

resource "aws_ecr_repository_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.ecr_repository_policy.json
}

data "aws_iam_policy_document" "ecr_repository_policy" {
  statement {
    sid    = "lambda"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
  }
}

# ==================================================
# Lambda Function
# ==================================================
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = local.function_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.function_name}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem"
    ]
    resources = ["arn:aws:dynamodb:${local.region}:${local.account_id}:table/${local.dynamodb_table_name}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ce:GetCostAndUsage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = local.function_policy_name
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.function_log_retention_in_days
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn
  image_uri     = "${aws_ecr_repository.this.repository_url}:latest"
  package_type  = "Image"
  architectures = ["arm64"]
  timeout       = var.timeout
  memory_size   = var.memory_size

  ephemeral_storage {
    size = local.ephemeral_storage_size
  }

  image_config {
    command = ["lambda_function.lambda_handler"]
  }

  logging_config {
    log_format = local.function_log_format
  }

  environment {
    variables = {
      COST_METRICS_VALUE = local.cost_metrics_value
      SETTINGS_TABLE     = local.dynamodb_table_name
      LINE_API_URL       = local.line_api_url
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role.lambda
  ]
}

# ==================================================
# EventBridge Scheduler
# ==================================================
data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "scheduler" {
  name               = local.scheduler_role_name
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}

data "aws_iam_policy_document" "scheduler_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [aws_lambda_function.this.arn]
  }
}

resource "aws_iam_role_policy" "scheduler" {
  name   = local.scheduler_policy_name
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_policy.json
}

resource "aws_scheduler_schedule" "this" {
  name  = local.scheduler_name
  state = var.scheduler_state

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = local.schedule_expression_tz

  flexible_time_window {
    mode = local.flexible_time_window
  }

  target {
    arn      = aws_lambda_function.this.arn
    role_arn = aws_iam_role.scheduler.arn
    retry_policy {
      maximum_retry_attempts       = local.maximum_retry_attempts
      maximum_event_age_in_seconds = local.maximum_event_age_in_seconds
    }
  }
}
