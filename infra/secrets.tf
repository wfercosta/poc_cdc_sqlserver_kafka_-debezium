
resource "aws_secretsmanager_secret" "db" {
  name = "${local.prefix}-rds-mssql-credentials-secret"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = local.username
    password = local.password
  })
}
