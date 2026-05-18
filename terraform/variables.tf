variable "aws_region" {
  description = "This varibles holds the value of AWS region"
  default     = "us-west-2"
}

variable "instances" {
  description = "Map of instance name to AMI IDs, SSH User, and OS family."

  #Created a map to tell the type of all variables
  type = map(object({
    ami           = string
    user          = string
    os_family     = string
    instance_type = string
  }))

  default = {
    "control-node-ubuntu" = {
      ami           = "ami-05d2d839d4f73aafb" #Ubuntu Server 24.04 LTS region: ap-south-1 
      user          = "ubuntu"
      os_family     = ""
      instance_type = "t3.micro"
    }
    "worker-ubuntu" = {
      ami           = "ami-05d2d839d4f73aafb" #Ubuntu Server 24.04 LTS region: ap-south-1 
      user          = "ubuntu"
      os_family     = ""
      instance_type = "t3.micro"
    }
    "worker-redhat" = {
      ami           = "ami-03793655b06c6e29a" #Red Hat Enterprise Linux version 10 (HVM) region: ap-south-1 
      user          = "ec2-user"
      os_family     = ""
      instance_type = "t3.micro"
    }
    "worker-amazon" = {
      ami           = "ami-045443a70fafb8bbc" # Amazon Linux 2023 (kernel-6.1), region: ap-south-1 
      user          = "ec2-user"
      os_family     = ""
      instance_type = "t3.micro"
    }
  }

}
