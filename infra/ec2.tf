resource "aws_security_group" "ec2" {
  name        = "${local.prefix}-bastion-host-sg"
  description = "Bastion host security group"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.prefix}-bastion-host-ec2-profile"
  role = element(module.iamsr.role_name, 0)
}

resource "aws_instance" "this" {
  ami                         = "ami-0a0e5d9c7acc336f1"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private[0].id
  security_groups             = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = false
  user_data = templatefile("_templates/ec2_user_data.tfpl", {
    db_address  = aws_db_instance.this.address,
    db_port     = aws_db_instance.this.port,
    db_name     = aws_db_instance.this.db_name,
    db_username = local.username,
    db_password = local.password
  })


  tags = {
    Name = "${local.prefix}-bastion-host"
  }
}
