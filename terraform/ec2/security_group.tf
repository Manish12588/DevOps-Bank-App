resource "aws_security_group" "bank_app" {
  name        = "devops-bank-ec2-sg"
  description = "Security group for DevOps Bank App EC2"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "devops-bank-ec2-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.bank_app.id
  description       = "SSH access"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "frontend" {
  security_group_id = aws_security_group.bank_app.id
  description       = "Frontend app"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "backend" {
  security_group_id = aws_security_group.bank_app.id
  description       = "Backend API"
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.bank_app.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
