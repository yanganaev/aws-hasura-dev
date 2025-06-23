# ----------------------------------------
# Security group for ALB
# ----------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.env}-alb-sg"
  description = "Allows incoming HTTP traffic to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-alb-sg"
    Project     = var.project_name
    Environment = var.env
  }
}

# ----------------------------------------
# Target Group for Hasura ECS service
# ----------------------------------------
resource "aws_lb_target_group" "hasura" {
  name        = "${var.project_name}-${var.env}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-tg"
    Project     = var.project_name
    Environment = var.env
  }
}

# ----------------------------------------
# Application Load Balancer
# ----------------------------------------
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets

  tags = {
    Name        = "${var.project_name}-${var.env}-alb"
    Project     = var.project_name
    Environment = var.env
  }
}

# ----------------------------------------
# HTTP Listener
# ----------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hasura.arn
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-http-listener"
    Project     = var.project_name
    Environment = var.env
  }
}

# ----------------------------------------
# Outputs
# ----------------------------------------
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "ecs_target_group_arn" {
  description = "Target Group ARN for ECS Service"
  value       = aws_lb_target_group.hasura.arn
}

# ----------------------------------------
# Variables
# ----------------------------------------
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "container_port" {
  description = "Port Hasura exposes"
  type        = number
}

variable "domain_name" {
  description = "Domain name (optional)"
  type        = string
}
