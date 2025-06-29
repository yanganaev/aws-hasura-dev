# terraform/modules/rds/main.tf
# Terraform module for creating an Amazon RDS Aurora PostgreSQL-compatible cluster

# Generate a random suffix to ensure unique names
resource "random_id" "suffix" {
  byte_length = 2
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.env}-rds-sg"
  description = "Security group for RDS cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-rds-sg"
    Project     = var.project_name
    Environment = var.env
  }
}

# RDS subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.env}-rds-subnet-group-${random_id.suffix.hex}"
  subnet_ids = var.private_subnets

  tags = {
    Name        = "${var.project_name}-${var.env}-rds-subnet-group"
    Project     = var.project_name
    Environment = var.env
  }
}

# Aurora PostgreSQL Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.project_name}-${var.env}-aurora-pg"
  engine                  = "aurora-postgresql"
  engine_version          = "13.18"
  database_name           = "hasuradb"
  master_username         = var.db_master_username
  master_password         = var.db_master_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  preferred_backup_window = "03:00-05:00"
  backup_retention_period = 1
  apply_immediately       = true

  tags = {
    Name        = "${var.project_name}-${var.env}-aurora-pg"
    Project     = var.project_name
    Environment = var.env
  }
}

# Aurora Instance
resource "aws_rds_cluster_instance" "main" {
  count                = 1
  identifier           = "${var.project_name}-${var.env}-aurora-pg-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = "db.t3.medium"
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  publicly_accessible  = false
  promotion_tier       = 0
  apply_immediately    = true

  tags = {
    Name        = "${var.project_name}-${var.env}-aurora-pg-instance-${count.index}"
    Project     = var.project_name
    Environment = var.env
  }
}

# Output values
output "db_cluster_endpoint" {
  description = "Endpoint of the RDS cluster"
  value       = aws_rds_cluster.main.endpoint
}

output "db_cluster_arn" {
  description = "ARN of the RDS cluster"
  value       = aws_rds_cluster.main.arn
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

# Variables
variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "env" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where RDS will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
}

variable "db_master_username" {
  description = "Master username for the PostgreSQL database"
  type        = string
}

variable "db_master_password" {
  description = "Master password for the PostgreSQL database"
  type        = string
  sensitive   = true
}
