terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state — stored in S3 so state is shared and not lost
  backend "s3" {
    bucket = "devops-bank-app-tfstate"
    key    = "ec2/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-bank-app"
      ManagedBy   = "terraform"
      Environment = "production"
    }
  }
}

/**
1. Tells Terraform which version of itself and which providers to use
2. Configures where to store the state file

State file:
Terraform keeps a record of everything it created in a file called terraform.tfstate. This is how it knows:

1. What already exists (don't recreate)
2. What changed (needs update)
3. What was removed (needs destroy)
*/
