output "role_name" {
  value = [
    for role in aws_iam_role.this : role.name
  ]
}

output "role_arn" {
  value = [
    for role in aws_iam_role.this : role.arn
  ]
}

