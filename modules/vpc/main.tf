# terraform/modules/vpc/main.tf
# Terraform module for creating network infrastructure (VPC, subnets, IGW, NAT Gateway)

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.env}-vpc"
    Project     = var.project_name
    Environment = var.env
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.env}-igw"
    Project     = var.project_name
    Environment = var.env
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets_cidr[count.index]
  availability_zone = var.azs[count.index] # Bind to availability zones
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.env}-public-subnet-${count.index + 1}"
    Project     = var.project_name
    Environment = var.env
  }
}

# Private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets_cidr[count.index]
  availability_zone = var.azs[count.index] # Bind to availability zones
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-${var.env}-private-subnet-${count.index + 1}"
    Project     = var.project_name
    Environment = var.env
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  # FIX: Removed 'vpc = true' as it's deprecated and caused an error.
  # EIPs created without a network interface are now implicitly for VPC.

  tags = {
    Name        = "${var.project_name}-${var.env}-nat-eip"
    Project     = var.project_name
    Environment = var.env
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Place NAT Gateway in the first public subnet

  tags = {
    Name        = "${var.project_name}-${var.env}-nat-gateway"
    Project     = var.project_name
    Environment = var.env
  }
  depends_on = [aws_internet_gateway.main] # NAT Gateway requires an IGW
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-public-rt"
    Project     = var.project_name
    Environment = var.env
  }
}

# Association of public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-private-rt"
    Project     = var.project_name
    Environment = var.env
  }
}

# Association of private subnets with the private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Output values for the VPC module
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = [for s in aws_subnet.private : s.id]
}

# Variables for the VPC module
variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "env" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets_cidr" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones for deployment"
  type        = list(string)
}
