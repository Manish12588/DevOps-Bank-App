# ── EKS Outputs 

output "vpc_id" {
  description = "VPC ID — referenced by EC2 workspace via remote state"
  value       = aws_vpc.main.id
}

output "public_subnet_a_id" {
  description = "Public subnet AZ-a ID — referenced by EC2 workspace"
  value       = aws_subnet.public_a.id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_version" {
  description = "EKS Kubernetes version"
  value       = aws_eks_cluster.main.version
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}
