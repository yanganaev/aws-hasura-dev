variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "env" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ECS networking"
  type        = string
}

variable "private_subnets" {
  description = "Private subnets for ECS service"
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
  description = "CPU units for ECS task"
  type        = number
}

variable "memory" {
  description = "Memory (MB) for ECS task"
  type        = number
}

variable "ecs_target_group_arn" {
  description = "ARN of target group for ALB"
  type        = string
}
