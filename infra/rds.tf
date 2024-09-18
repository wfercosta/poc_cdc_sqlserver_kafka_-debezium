resource "aws_security_group" "rds" {
  name        = "${local.prefix}-mssql-sg"
  description = "MSSQL Security Group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.prefix}-rds-subnet-group"
  subnet_ids = [aws_subnet.private[0].id, aws_subnet.private[1].id]
}

# resource "aws_db_instance" "this" {
#   engine                 = "sqlserver-ex"
#   license_model          = "license-included"
#   engine_version         = "15.00"
#   instance_class         = "db.t3.micro"
#   allocated_storage      = 20
#   storage_type           = "gp2"
#   skip_final_snapshot    = true
#   username               = local.username
#   password               = local.password
#   db_subnet_group_name   = aws_db_subnet_group.this.name
#   vpc_security_group_ids = [aws_security_group.rds.id]
# }

resource "aws_db_instance" "this" {
  identifier             = "${local.prefix}-rds-mssql"
  engine                 = "sqlserver-se"
  license_model          = "license-included"
  engine_version         = "15.00.4385.2.v1"
  instance_class         = "db.t3.xlarge"
  allocated_storage      = 20
  storage_type           = "gp2"
  skip_final_snapshot    = true
  username               = local.username
  password               = local.password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
}
