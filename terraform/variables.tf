variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "dockerhub_username" {
  description = "DockerHub username to pull images from"
  type        = string
}

variable "dockerhub_token" {
  description = "DockerHub access token"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret for backend authentication"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
  default     = "bankpass"
}

variable "public_subnet_cidr_a" {
  description = "CIDR for public subnet AZ-a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_b" {
  description = "CIDR for public subnet AZ-b"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr_a" {
  description = "CIDR for private subnet AZ-a"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR for private subnet AZ-b"
  type        = string
  default     = "10.0.4.0/24"
}

/**
--> Three parts of a variable:

1. description — what it's for (always write this)
2. type — string, number, bool, list, map
3. default — optional fallback if not provided

--> Key things to remember:

1. Variables with no default are required — Terraform will prompt if not provided
2. Never put actual secret values here — only declare the variable
3. Actual values go in terraform.tfvars
4. Think of variables.tf as the public API of your config — what can be customized

*/
