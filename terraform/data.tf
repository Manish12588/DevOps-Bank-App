# Automatically picks the most recent patched version
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

/**
--> What it does:
Reads information from AWS without creating anything. Used to look up existing resources.

--> Key things to remember:

owners = ["099720109477"] is Canonical's AWS account ID — always include this to avoid fake AMIs
Reference data source output with: data.aws_ami.ubuntu.id
Data sources run during terraform plan — they query AWS live
*/
