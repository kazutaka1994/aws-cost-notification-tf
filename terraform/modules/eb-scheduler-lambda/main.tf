data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}


data "aws_iam_policy_document" "default" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "default" {
  name               = var.scheduler_role_name
  assume_role_policy = data.aws_iam_policy_document.default.json
}

resource "aws_iam_role_policy" "default" {
  name = var.scheduler_role_name
  role = aws_iam_role.default.id
  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Resource" : var.scheduler_target_arn
      }
    ]
  })
}

resource "aws_scheduler_schedule" "default" {
  name  = var.scheduler_name
  state = var.scheduler_state

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_tz

  flexible_time_window {
    mode = var.flexible_time_window
  }

  target {
    arn      = var.scheduler_target_arn
    role_arn = aws_iam_role.default.arn
    retry_policy {
      maximum_retry_attempts       = var.maximum_retry_attempts
      maximum_event_age_in_seconds = var.maximum_event_age_in_seconds
    }
  }
}