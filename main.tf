terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1" # обязательная версия для exclude_characters
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  azs                  = var.azs
}

module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  env                = var.env
  vpc_id             = module.vpc.vpc_id
  private_subnets    = module.vpc.private_subnets
  db_master_username = data.aws_ssm_parameter.rds_master_username.value
  db_master_password = data.aws_ssm_parameter.rds_master_password.value
}

module "bastion" {
  source         = "./modules/bastion"
  project_name   = var.project_name
  env            = var.env
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  instance_type  = "t3.micro"
  key_name       = "hasura-dev-key"
}

resource "aws_ssm_parameter" "db_endpoint" {
  name      = "/dev/hasura/rds/db_endpoint"
  type      = "String"
  value     = module.rds.db_cluster_endpoint
  overwrite = true
}

resource "aws_ssm_parameter" "hasura_db_url" {
  name      = "/dev/hasura/db_url"
  type      = "SecureString"
  value     = "postgresql://${data.aws_ssm_parameter.rds_master_username.value}:${data.aws_ssm_parameter.rds_master_password.value}@${module.rds.db_cluster_endpoint}:5432/hasuradb"
  overwrite = true

  tags = {
    Name = "Hasura DB URL"
    Env  = var.env
  }

  depends_on = [module.rds]
}

module "db_configurator" {
  source = "./modules/db_configurator"

  depends_on            = [module.rds]
  project_name          = var.project_name
  env                   = var.env
  vpc_id                = module.vpc.vpc_id
  private_subnets       = module.vpc.private_subnets
  rds_security_group_id = module.rds.rds_security_group_id
  aws_region            = data.aws_region.current.id
  aws_account_id        = data.aws_caller_identity.current.account_id
}

module "ecs" {
  source               = "./modules/ecs"
  project_name         = var.project_name
  env                  = var.env
  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_subnets
  container_port       = var.hasura_container_port
  hasura_image         = var.hasura_image
  cpu                  = var.hasura_cpu
  memory               = var.hasura_memory
  ecs_target_group_arn = module.alb.ecs_target_group_arn
}



module "alb" {
  source         = "./modules/alb"
  project_name   = var.project_name
  env            = var.env
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  container_port = var.hasura_container_port
  domain_name    = data.aws_ssm_parameter.domain_name.value
}

module "route53" {
  source        = "./modules/route53"
  domain_name   = data.aws_ssm_parameter.domain_name.value
  alb_dns_name  = module.alb.alb_dns_name
  alb_zone_id   = module.alb.alb_zone_id
}

resource "aws_security_group_rule" "ecs_to_rds_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.ecs.ecs_service_security_group_id
  security_group_id        = module.rds.rds_security_group_id
  description              = "Allow ECS tasks to connect to RDS PostgreSQL"
}

resource "aws_security_group_rule" "db_configurator_to_rds_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.db_configurator.configurator_security_group_id
  security_group_id        = module.rds.rds_security_group_id
  description              = "Allow DB Configurator EC2 to connect to RDS PostgreSQL"
}

resource "aws_security_group_rule" "bastion_to_rds_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.bastion.bastion_sg_id
  security_group_id        = module.rds.rds_security_group_id
  description              = "Allow Bastion to connect to RDS PostgreSQL"
}

data "aws_ssm_parameter" "rds_master_username" {
  name = "/dev/hasura/rds/master_username"
}

data "aws_ssm_parameter" "rds_master_password" {
  name            = "/dev/hasura/rds/master_password"
  with_decryption = true
}

data "aws_ssm_parameter" "hasura_graphql_admin_secret" {
  name            = "/dev/hasura/admin_secret"
  with_decryption = true
}

data "aws_ssm_parameter" "domain_name" {
  name = "/dev/hasura/domain_name"
}

output "db_endpoint" {
  value = module.rds.db_cluster_endpoint
}

output "hasura_db_url" {
  value     = aws_ssm_parameter.hasura_db_url.value
  sensitive = true
}
