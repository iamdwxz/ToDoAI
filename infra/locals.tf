locals {
  name_prefix = var.project_name

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # The ALB requires subnets in at least two different Availability Zones.
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  # Reuse the existing repository and image tag; nothing is created in ECR.
  # The tag is resolved to a digest so deployments are reproducible.
  ecr_repository_url = data.aws_ecr_repository.app.repository_url
  ecr_registry       = split("/", data.aws_ecr_repository.app.repository_url)[0]
  image_digest       = data.aws_ecr_image.app.image_digest
  image_uri          = "${data.aws_ecr_repository.app.repository_url}@${data.aws_ecr_image.app.image_digest}"

  route53_zone_id = var.create_route53_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.this[0].zone_id
}
