# Region
provider "aws" {
  region = var.aws_region
}

# Key Value pair
resource "aws_key_pair" "my_key_pair" {
  key_name   = "terra-automate-key"
  public_key = file("terra-automate-key.pub")
}

# VPC Default
resource "aws_default_vpc" "default" {
}

# Security Group 
resource "aws_security_group" "my_security_group" {

  name        = "terra-security-group"
  vpc_id      = aws_default_vpc.default.id # interpolation
  description = "this is Inbound and outbound rules for your instance Security group"

}

# Inbound & Outbount port rules
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.my_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.my_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.my_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# EC2 instance
resource "aws_instance" "my_instance" {

  for_each               = var.instances                             #Total given 4 instances
  ami                    = each.value.ami                            # Get the AMI value of each instances
  instance_type          = each.value.instance_type                  # Instance Type
  key_name               = aws_key_pair.my_key_pair.key_name         # Key pair
  vpc_security_group_ids = [aws_security_group.my_security_group.id] # VPC & Security Group

  # root storage (EBS)
  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name     = each.key
    OSFamily = each.value.os_family
  }
}

# ------ Generate the Hosts file -----#
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    instances = {
      for name, inst in aws_instance.my_instance : name => {
        public_ip = inst.public_ip
        user      = var.instances[name].user
        os_family = var.instances[name].os_family
      }
    }
    ssh_key_path = "${path.module}/terra-automate-key"
  })

  filename        = "${path.module}/inventories/dev/hosts.ini"
  file_permission = "0644"
}

# ------- Install Ansible on Controler node -----#
resource "null_resource" "setup_controller" {
  depends_on = [local_file.ansible_inventory]

  #Create keys directory on controller
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/keys"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/terra-automate-key")
      host        = aws_instance.my_instance["control-node-ubuntu"].public_ip
    }
  }

  #Copy Private key to controler node
  provisioner "file" {
    source      = "${path.module}/terra-automate-key"
    destination = "/home/ubuntu/keys/terra-automate-key"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/terra-automate-key")
      host        = aws_instance.my_instance["control-node-ubuntu"].public_ip
    }
  }

  #Install ansible on controler node
  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ubuntu/keys/terra-automate-key",
      "sudo apt-add-repository ppa:ansible/ansible -y",
      "sudo apt update -y ",
      "sudo apt install ansible -y",
      "ansible --version"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/terra-automate-key")
      host        = aws_instance.my_instance["control-node-ubuntu"].public_ip
    }
  }

}
