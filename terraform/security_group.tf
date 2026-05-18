# ── Security Group ────────────────────────────────────────────────────────────
# Acts as a firewall — controls what traffic can reach the EC2 instance
resource "aws_security_group" "bank_app" {
  name        = "devops-bank-sg"
  description = "Security group for DevOps Bank App"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "devops-bank-sg" }
}

# ── Ingress Rules (inbound traffic) ──────────────────────────────────────────

# SSH — restricted to your IP only (never open to 0.0.0.0/0)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.bank_app.id
  description       = "SSH access from my IP only"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "${var.my_ip}/32"
}

# Frontend — public access on port 8080
resource "aws_vpc_security_group_ingress_rule" "frontend" {
  security_group_id = aws_security_group.bank_app.id
  description       = "Frontend app access"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# Backend API — public access on port 3000
resource "aws_vpc_security_group_ingress_rule" "backend" {
  security_group_id = aws_security_group.bank_app.id
  description       = "Backend API access"
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ── Egress Rule (outbound traffic) ────────────────────────────────────────────
# Allow all outbound — needed for Docker pulls, apt-get, etc.
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.bank_app.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
