[bank_app]
${ec2_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${ssh_key}.pem

[bank_app:vars]
ansible_python_interpreter=/usr/bin/python3
