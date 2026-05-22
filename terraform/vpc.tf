# ── VPC ───────────────────────────────────────────────────────────────────────
# Isolated network for all bank app resources
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # allows EC2 to get a public DNS name
  enable_dns_support   = true

  tags = { Name = "devops-bank-vpc" }
}

# ── Public Subnet ─────────────────────────────────────────────────────────────
# EC2 lives here — map_public_ip_on_launch gives it a public IP automatically
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = { Name = "devops-bank-public-subnet" }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────
# Without this, the VPC has no route to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "devops-bank-igw" }
}

# ── Route Table ───────────────────────────────────────────────────────────────
# Tells the subnet: send all internet traffic (0.0.0.0/0) to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "devops-bank-public-rt" }
}

# ── Route Table Association ───────────────────────────────────────────────────
# Links the route table to the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
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
