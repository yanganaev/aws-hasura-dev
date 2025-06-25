resource "random_password" "admin_secret" {
  length  = 32
  special = true
}

resource "random_password" "master_password" {
  length           = 20
  override_special = "!#$%^&*()-_=+[]{}<>?.,"  # Allowed special characters
  special          = true
  upper            = true
  lower            = true
  number           = true
}

variable "domain_name" {
  type    = string
  default = "hasura.dev.mydomain.com" # Replace with your actual domain
}

variable "master_username" {
  type    = string
  default = "hasura_admin"
}

resource "aws_ssm_parameter" "admin_secret" {
  name      = "/dev/hasura/admin_secret"
  type      = "SecureString"
  value     = random_password.admin_secret.result
  overwrite = true

  tags = {
    Name = "Hasura Admin Secret"
  }
}

resource "aws_ssm_parameter" "db_url" {
  name      = "/dev/hasura/db_url"
  type      = "String"
  value     = "postgres://${var.master_username}:${random_password.master_password.result}@host.dns.name:5432/hasura"
  overwrite = true

  tags = {
    Name = "Hasura DB URL"
  }
}

resource "aws_ssm_parameter" "domain_name" {
  name      = "/dev/hasura/domain_name"
  type      = "String"
  value     = var.domain_name
  overwrite = true

  tags = {
    Name = "Hasura Domain Name"
  }
}

resource "aws_ssm_parameter" "rds_db_endpoint" {
  name      = "/dev/hasura/rds/db_endpoint"
  type      = "String"
  value     = "host.dns.name" # Replace with your RDS Cluster endpoint
  overwrite = true

  tags = {
    Name = "Hasura RDS Endpoint"
  }
}

resource "aws_ssm_parameter" "rds_master_password" {
  name      = "/dev/hasura/rds/master_password"
  type      = "SecureString"
  value     = random_password.master_password.result
  overwrite = true

  tags = {
    Name = "Hasura RDS Master Password"
  }
}

resource "aws_ssm_parameter" "rds_master_username" {
  name      = "/dev/hasura/rds/master_username"
  type      = "String"
  value     = var.master_username
  overwrite = true

  tags = {
    Name = "Hasura RDS Master Username"
  }
}
