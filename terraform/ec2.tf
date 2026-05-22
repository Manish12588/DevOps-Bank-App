# ── EC2 Instance ──────────────────────────────────────────────────────────────
resource "aws_instance" "devops_bank_server" {
  ami                    = data.aws_ami.ubuntu.id #Get the ami value
  instance_type          = var.instance_type      #Instance Type
  subnet_id              = aws_subnet.public.id   #
  key_name               = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.bank_app.id]

  # Root volume — 20GB is enough for Docker images
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = { Name = "devops-bank-server" }
}
