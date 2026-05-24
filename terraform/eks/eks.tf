# ── EKS Cluster ───────────────────────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = "devops-bank-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]
    endpoint_public_access  = true # kubectl access from your laptop
    endpoint_private_access = true # nodes communicate internally
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = { Name = "devops-bank-eks" }
}

# ── EKS Node Group ────────────────────────────────────────────────────────────
# Managed node group — AWS handles node lifecycle
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "devops-bank-nodes"
  node_role_arn   = aws_iam_role.eks_node.arn

  # Worker nodes live in private subnets
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  # Node configuration
  instance_types = ["t3.medium"] # minimum for running K8s + app

  scaling_config {
    desired_size = 2 # start with 2 nodes
    min_size     = 1
    max_size     = 3
  }

  update_config {
    max_unavailable = 1 # rolling update — keep 1 node available
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]

  tags = { Name = "devops-bank-nodes" }
}
