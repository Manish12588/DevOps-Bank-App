# ── VPC ───────────────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name                                    = "devops-bank-vpc"
    "kubernetes.io/cluster/devops-bank-eks" = "shared"
  }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "devops-bank-igw" }
}

# ── Public Subnet AZ-a (EC2 lives here) ──────────────────────────────────────
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_a
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name                                    = "devops-bank-public-subnet-a"
    "kubernetes.io/cluster/devops-bank-eks" = "shared"
    "kubernetes.io/role/elb"                = "1"
  }
}

# ── Public Subnet AZ-b (EKS requirement) ─────────────────────────────────────
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_b
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name                                    = "devops-bank-public-subnet-b"
    "kubernetes.io/cluster/devops-bank-eks" = "shared"
    "kubernetes.io/role/elb"                = "1"
  }
}

# ── Private Subnet AZ-a (EKS worker nodes) ───────────────────────────────────
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                                    = "devops-bank-private-subnet-a"
    "kubernetes.io/cluster/devops-bank-eks" = "shared"
    "kubernetes.io/role/internal-elb"       = "1"
  }
}

# ── Private Subnet AZ-b (EKS worker nodes) ───────────────────────────────────
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_b
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                                    = "devops-bank-private-subnet-b"
    "kubernetes.io/cluster/devops-bank-eks" = "shared"
    "kubernetes.io/role/internal-elb"       = "1"
  }
}

# ── NAT Gateway ───────────────────────────────────────────────────────────────
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  tags       = { Name = "devops-bank-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags          = { Name = "devops-bank-nat" }
  depends_on    = [aws_internet_gateway.main]
}

# ── Public Route Table (via IGW) ──────────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "devops-bank-public-rt" }
}

# ── Private Route Table (via NAT) ─────────────────────────────────────────────
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "devops-bank-private-rt" }
}

# ── Route Table Associations ──────────────────────────────────────────────────
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

/**
VPC — isolated private network. Everything lives inside it. Without VPC nothing communicates.

Subnet — a slice of the VPC. EC2 lives in a subnet. Public subnet = has route to internet.

Internet Gateway — the door between your VPC and the internet. Without it, nothing can reach the outside world.

Route Table — the map. Tells traffic where to go:
destination 0.0.0.0/0 → send to Internet Gateway

Route Table Association — links the route table to the subnet. Without this, the subnet doesn't use the route table.

--> Key things to remember:

1. map_public_ip_on_launch = true — automatically assigns public IP to EC2 in this subnet
2. enable_dns_hostnames = true — EC2 gets a DNS name like ec2-x-x-x-x.compute.amazonaws.com
3. Order matters conceptually: VPC → IGW → Subnet → Route Table → Association
4. Terraform handles the creation order automatically via dependency graph
5. CIDR 10.0.0.0/16 = 65,536 IPs for the VPC
6. CIDR 10.0.1.0/24 = 256 IPs for the subnet — must be inside VPC CIDR
*/
