# terraform/outputs.tf
# All output values for the root Terraform module

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "rds_cluster_endpoint" {
  description = "Endpoint of the RDS cluster"
  value       = module.rds.db_cluster_endpoint
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "hasura_url" {
  description = "The expected URL to access Hasura"
  value       = "https://${data.aws_ssm_parameter.domain_name.value}"
  sensitive   = true
}

output "db_configurator_instance_id" {
  description = "ID of the temporary DB configurator EC2 instance"
  value       = module.db_configurator.instance_id
}

output "db_configurator_sg_id" {
  description = "ID of the DB configurator security group"
  value       = module.db_configurator.configurator_security_group_id
}

output "bastion_instance_id" {
  description = "ID of the Bastion EC2 instance"
  value       = module.bastion.bastion_instance_id
}

output "bastion_sg_id" {
  description = "Security group ID of the Bastion"
  value       = module.bastion.bastion_sg_id
}