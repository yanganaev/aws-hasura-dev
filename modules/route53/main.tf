# terraform/modules/route53/main.tf
# Terraform module for creating a Route 53 A-record

# Retrieve the existing Hosted Zone
# Assumes you already have a parent Hosted Zone (e.g., your-test-domain.com)
data "aws_route53_zone" "selected" {
  name         = "yanganaev.xyz."  #
  private_zone = false
}

# Route 53 A Record для ALB
resource "aws_route53_record" "hasura_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Variables for the Route 53 module
variable "domain_name" {
  description = "Full domain name for the record (e.g., dev.your-test-domain.com)"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS имя Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Зона ID Application Load Balancer"
  type        = string
}