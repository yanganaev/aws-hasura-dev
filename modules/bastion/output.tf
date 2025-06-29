output "bastion_instance_id" {
  description = "ID of the Bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "bastion_sg_id" {
  description = "Security group ID for Bastion host"
  value       = aws_security_group.bastion_sg.id
}
