#what to print after apply (EC2 IP etc)
# ── Outputs ───────────────────────────────────────────────────────────────────
# These are printed after terraform apply
# Use them to update GitHub Secrets and test the deployment

output "instance_public_ip" {
  description = "Public IP of the bank server — update EC2_SSH_HOST in GitHub Secrets"
  value       = aws_instance.devops_bank_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the bank server"
  value       = aws_instance.devops_bank_server.public_dns
}

output "app_url" {
  description = "URL to access the bank app"
  value       = "http://${aws_instance.devops_bank_server.public_ip}:8080"
}

output "api_url" {
  description = "URL to access the backend API"
  value       = "http://${aws_instance.devops_bank_server.public_ip}:3000"
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.devops_bank_server.public_ip}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}
