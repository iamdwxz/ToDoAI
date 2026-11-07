# Public hosted zone for the application domain.
# Terraform does not modify the parent zone or the registrar's nameserver delegation.
resource "aws_route53_zone" "this" {
  count = var.create_route53_zone ? 1 : 0

  name          = var.domain_name
  comment       = "ToDoAI public zone managed by Terraform"
  force_destroy = false

  tags = {
    Name = var.domain_name
  }
}

# Optional lookup when the zone already exists in the same AWS account.
data "aws_route53_zone" "this" {
  count = var.create_route53_zone ? 0 : 1

  name         = var.domain_name
  private_zone = false
}

# Alias records point at the ALB, so no hard-coded IP addresses are needed.
resource "aws_route53_record" "apex" {
  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = local.route53_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
