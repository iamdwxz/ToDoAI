output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the ALB target group."
  value       = aws_lb_target_group.app.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}

output "ecr_repository_url" {
  description = "URL of the pre-existing ECR repository."
  value       = local.ecr_repository_url
}

output "container_image" {
  description = "Digest-pinned image URI pulled by the instances."
  value       = local.image_uri
}

output "image_digest" {
  description = "Immutable digest resolved from the configured image tag."
  value       = local.image_digest
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID for the domain."
  value       = local.route53_zone_id
}

output "route53_name_servers" {
  description = "Nameservers to delegate at the parent DNS provider. Delegation is manual."
  value       = var.create_route53_zone ? aws_route53_zone.this[0].name_servers : data.aws_route53_zone.this[0].name_servers
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate, or null when HTTPS is disabled."
  value       = var.enable_https ? aws_acm_certificate.this[0].arn : null
}

output "https_enabled" {
  description = "Whether the HTTPS listener and certificate validation are enabled."
  value       = var.enable_https
}

output "website_url" {
  description = "URL to use once DNS is reachable."
  value       = var.enable_https ? "https://${var.domain_name}" : "http://${var.domain_name}"
}

output "instance_security_group_id" {
  description = "Security group attached to the EC2 instances."
  value       = aws_security_group.instance.id
}
