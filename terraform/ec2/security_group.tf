resource "aws_security_group" "bank_app" {
  name        = "devops-bank-sg"
  description = "Security group for DevOps Bank App"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id
  tags        = { Name = "devops-bank-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.bank_app.id
  description       = "SSH access - open for CI/CD pipeline"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "frontend" {
  security_group_id = aws_security_group.bank_app.id
  description       = "Frontend app access"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "backend" {
  security_group_id = aws_security_group.bank_app.id
  description       = "Backend API access"
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.bank_app.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
