# Generate secure admin_secret (no wildcards)
resource "random_password" "admin_secret" {
  length  = 32
  special = false
}

# Generate master_password (no wildcards)
resource "random_password" "master_password" {
  length  = 20
  special = false
}

# Домен
variable "domain_name" {
  type    = string
  default = "hasura.dev.mydomain.com" # replace with actual
}

# User name PostgreSQL
variable "master_username" {
  type    = string
  default = "hasura_admin"
}

# SSM parameters

resource "aws_ssm_parameter" "admin_secret" {
  name      = "/dev/hasura/admin_secret"
  type      = "SecureString"
  value     = random_password.admin_secret.result
  overwrite = true

  tags = {
    Name = "Hasura Admin Secret"
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

resource "aws_ssm_parameter" "domain_name" {
  name      = "/dev/hasura/domain_name"
  type      = "String"
  value     = var.domain_name
  overwrite = true

  tags = {
    Name = "Hasura Domain Name"
  }
}
