# terraform/modules/ecs/main.tf
# ----------------------------------------
# ECS Cluster
# ----------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.env}-cluster"

  tags = {
    Name        = "${var.project_name}-${var.env}-cluster"
    Project     = var.project_name
    Environment = var.env
  }
}

# ----------------------------------------
# IAM Role for ECS Task Execution
# ----------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.env}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.env}-ecs-task-execution-role"
    Project     = var.project_name
    Environment = var.env
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow ECS task to access SSM + KMS for secrets
resource "aws_iam_policy" "ssm_parameter_store_access" {
  name        = "${var.project_name}-${var.env}-ssm-param-read-policy"
  description = "Allows ECS task to read SecureString parameters"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["ssm:GetParameters", "ssm:GetParameter", "ssm:GetParametersByPath"],
        Effect   = "Allow",
        Resource = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/dev/hasura/*"
      },
      {
        Action   = ["kms:Decrypt"],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_access_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_parameter_store_access.arn
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ----------------------------------------
# CloudWatch Log Group
# ----------------------------------------
resource "aws_cloudwatch_log_group" "hasura" {
  name              = "/ecs/${var.project_name}-${var.env}-hasura"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.env}-hasura-logs"
    Project     = var.project_name
    Environment = var.env
  }
}

# ----------------------------------------
# ECS Task Definition for Hasura
# ----------------------------------------
resource "aws_ecs_task_definition" "hasura" {
  family                   = "${var.project_name}-${var.env}-hasura-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "hasura"
      image     = var.hasura_image
      cpu       = var.cpu
      memory    = var.memory
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "HASURA_GRAPHQL_ENABLE_CONSOLE"
          value = "true"
        },
        {
          name  = "HASURA_GRAPHQL_DEV_MODE"
          value = "true"
        },
        {
          name  = "HASURA_GRAPHQL_LOG_LEVEL"
          value = "warn"
        }
      ]

      secrets = [
        {
          name      = "HASURA_GRAPHQL_ADMIN_SECRET"
          valueFrom = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/dev/hasura/admin_secret"
        },
        {
          name      = "HASURA_GRAPHQL_DATABASE_URL"
          valueFrom = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/dev/hasura/db_url"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.hasura.name
          awslogs-region        = data.aws_region.current.id
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.env}-hasura-task"
    Project     = var.project_name
    Environment = var.env
  }
}

# ----------------------------------------
# Security Group
# ----------------------------------------
resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-${var.env}-ecs-service-sg"
  description = "Security group for Hasura ECS service"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.env}-ecs-service-sg"
    Project     = var.project_name
    Environment = var.env
  }
}

# ----------------------------------------
# ECS Service
# ----------------------------------------
resource "aws_ecs_service" "hasura" {
  name            = "${var.project_name}-${var.env}-hasura-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.hasura.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.ecs_target_group_arn
    container_name   = "hasura"
    container_port   = var.container_port
  }

  depends_on = [aws_cloudwatch_log_group.hasura]

  tags = {
    Name        = "${var.project_name}-${var.env}-hasura-service"
    Project     = var.project_name
    Environment = var.env
  }
}

# ----------------------------------------
# Outputs
# ----------------------------------------
output "ecs_cluster_id" {
  value       = aws_ecs_cluster.main.id
  description = "ECS Cluster ID"
}

output "ecs_service_arn" {
  value       = aws_ecs_service.hasura.arn
  description = "ECS Service ARN"
}

output "ecs_service_security_group_id" {
  value       = aws_security_group.ecs_service.id
  description = "Security Group ID for ECS Service"
}

# ----------------------------------------
# Variables
# ----------------------------------------
variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "container_port" {
  description = "Port exposed by the Hasura container"
  type        = number
}

variable "hasura_image" {
  description = "Docker image for Hasura"
  type        = string
}

variable "cpu" {
  description = "CPU units for ECS Fargate task"
  type        = number
}

variable "memory" {
  description = "Memory (MB) for ECS Fargate task"
  type        = number
}

variable "hasura_graphql_admin_secret" {
  description = "Hasura admin secret"
  type        = string
  sensitive   = true
}

variable "ecs_target_group_arn" {
  description = "Target group ARN from ALB module"
  type        = string
}
