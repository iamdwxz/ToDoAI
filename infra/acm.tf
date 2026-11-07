# Certificate for the apex domain and the www hostname.
# ACM must live in the same region as the ALB (eu-central-1), unlike CloudFront.
#
# The certificate is created only when HTTPS is explicitly enabled. Requesting it
# earlier would start ACM's 72-hour validation window while the Route 53 zone is
# still waiting for external NS delegation, leaving a timed-out certificate behind.
resource "aws_acm_certificate" "this" {
  count = var.enable_https ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.name_prefix}-certificate"
  }
}

# DNS validation records are written into the Route 53 zone managed by this stack.
# No external nameservers or parent-zone records are touched here.
resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_https ? {
    for option in aws_acm_certificate.this[0].domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  } : {}

  allow_overwrite = true
  zone_id         = local.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
}

# The validation waiter runs only when HTTPS is enabled, after the hosted zone is
# authoritative for the domain. This prevents a 30-minute wait that cannot succeed.
resource "aws_acm_certificate_validation" "this" {
  count = var.enable_https ? 1 : 0

  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "30m"
  }
}
