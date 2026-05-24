# Auto-generate Ansible inventory after terraform apply
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    ec2_ip  = aws_instance.devops_bank_server.public_ip
    ssh_key = aws_key_pair.my_key_pair.key_name
  })
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"

  depends_on = [aws_instance.devops_bank_server]
}
