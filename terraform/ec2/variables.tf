variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16" # different from EKS VPC (10.0.0.0/16)
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "dockerhub_username" {
  description = "DockerHub username"
  type        = string
  default     = ""
}

variable "dockerhub_token" {
  description = "DockerHub access token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_secret" {
  description = "JWT secret for backend"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
  default     = "bankpass"
}
