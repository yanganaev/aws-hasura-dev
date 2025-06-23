# terraform/modules/db_configurator/main.tf
# Module for launching a temporary EC2 instance to configure PostgreSQL

resource "aws_security_group" "configurator_sg" {
  name        = "${var.project_name}-${var.env}-db-configurator-sg"
  description = "Security group for the temporary DB configurator EC2 instance"
  vpc_id      = var.vpc_id

  # Allow outbound to RDS (PostgreSQL)
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.rds_security_group_id] # Allow outbound only to RDS SG
    description     = "Allow outbound to RDS PostgreSQL"
  }

  # Allow outbound to SSM endpoints (for fetching parameters) and package managers
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Can be restricted to VPC endpoints for SSM if needed
    description = "Allow outbound HTTPS (SSM, package managers)"
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound HTTP (package managers)"
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-db-configurator-sg"
    Project     = var.project_name
    Environment = var.env
  }
}

resource "aws_iam_role" "configurator_role" {
  name = "${var.project_name}-${var.env}-db-configurator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.env}-db-configurator-role"
    Project     = var.project_name
    Environment = var.env
  }
}

resource "aws_iam_instance_profile" "configurator_profile" {
  name = "${var.project_name}-${var.env}-db-configurator-profile"
  role = aws_iam_role.configurator_role.name
}

# Policy to allow reading SSM parameters (needed by configure_postgres.py)
resource "aws_iam_policy" "configurator_ssm_read_policy" {
  name        = "${var.project_name}-${var.env}-db-configurator-ssm-read-policy"
  description = "Allows the DB configurator EC2 to read SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParametersByPath"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/dev/hasura/*"
        ]
      },
      {
        Action   = [
          "kms:Decrypt" # Required for SecureString parameters
        ],
        Effect   = "Allow",
        Resource = "*" # Can be restricted to a specific KMS key if used
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "configurator_ssm_read_attachment" {
  role       = aws_iam_role.configurator_role.name
  policy_arn = aws_iam_policy.configurator_ssm_read_policy.arn
}

# Policy for CloudWatch Logs (to see user_data output)
resource "aws_iam_role_policy_attachment" "configurator_cloudwatch_attachment" {
  role       = aws_iam_role.configurator_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" # Basic CloudWatch access
}


resource "aws_instance" "db_configurator" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro" # Smallest instance type
  subnet_id                   = element(var.private_subnets, 0) # Launch in one private subnet
  associate_public_ip_address = false # No public IP, access logs via CloudWatch
  vpc_security_group_ids      = [aws_security_group.configurator_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.configurator_profile.name
  user_data                   = file("${path.module}/user_data.sh") # THIS LINE IS THE KEY CHANGE

  tags = {
    Name        = "${var.project_name}-${var.env}-db-configurator"
    Project     = var.project_name
    Environment = var.env
    ConfiguratorInstance = "true"
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

output "instance_id" {
  value       = aws_instance.db_configurator.id
  description = "ID of the temporary DB configurator EC2 instance"
}

output "configurator_security_group_id" {
  value       = aws_security_group.configurator_sg.id
  description = "ID of the DB configurator's security group"
}

variable "project_name" { type = string }
variable "env" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "rds_security_group_id" { type = string }
variable "aws_region" { type = string }
variable "aws_account_id" { type = string }
