output "instance_public_ip" {
  description = "Public IP — update EC2_SSH_HOST in GitHub Secrets"
  value       = aws_instance.devops_bank_server.public_ip
}

output "app_url" {
  description = "URL to access the bank app"
  value       = "http://${aws_instance.devops_bank_server.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ~/.ssh/${aws_key_pair.my_key_pair.key_name}.pem ubuntu@${aws_instance.devops_bank_server.public_ip}"
}
