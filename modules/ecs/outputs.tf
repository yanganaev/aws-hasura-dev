output "ecs_service_security_group_id" {
  value       = aws_security_group.ecs_service.id
  description = "Security Group ID for ECS Service"
}
