output "scheduler_role_id" {
  value = aws_iam_role.default.id
}

output "scheduler_role_arn" {
  value = aws_iam_role.default.arn
}

output "scheduler_policy_name" {
  value = aws_iam_role.default.name
}

output "scheduler_id" {
  value = aws_scheduler_schedule.default.id
}

output "scheduler_arn" {
  value = aws_scheduler_schedule.default.arn
}
