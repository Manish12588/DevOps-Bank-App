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

  # Bootstrap script — runs once when EC2 first starts
  # Installs Docker, creates app folder, writes .env file
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update and install Docker
    apt-get update -y
    apt-get install -y docker.io docker-compose-v2

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Add ubuntu user to docker group (no sudo needed)
    usermod -aG docker ubuntu

    # Create app directory
    mkdir -p /home/ubuntu/devops-bank-app/database
    cd /home/ubuntu/devops-bank-app

    # Write environment file
    cat > .env << 'ENVEOF'
    DOCKERHUB_USER=${var.dockerhub_username}
    DOCKER_TAG=latest
    JWT_SECRET=${var.jwt_secret}
    DB_PASSWORD=${var.db_password}
    ENVEOF

    # Fix ownership
    chown -R ubuntu:ubuntu /home/ubuntu/devops-bank-app

    echo "Bootstrap complete" > /tmp/bootstrap-done.txt
  EOF

  tags = { Name = "devops-bank-server" }
}
