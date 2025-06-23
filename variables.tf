# terraform/variables.tf
# All variables for the root Terraform module

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "hasura"
}

variable "env" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "azs" {
  description = "List of availability zones for deployment"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"] # Change to appropriate AZs for your region
}

variable "hasura_container_port" {
  description = "The port on which Hasura listens for incoming connections"
  type        = number
  default     = 8080
}

variable "hasura_image" {
  description = "Docker image for Hasura GraphQL Engine"
  type        = string
  default     = "hasura/graphql-engine:v2.40.0"
}

variable "hasura_cpu" {
  description = "Number of vCPUs for the Hasura Fargate task"
  type        = number
  default     = 256 # 0.25 vCPU, Fargate min
}

variable "hasura_memory" {
  description = "Amount of memory (MB) for the Hasura Fargate task"
  type        = number
  default     = 512 # 0.5 GB, Fargate min
}
