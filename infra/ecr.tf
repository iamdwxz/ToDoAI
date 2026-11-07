# The ECR repository already exists. This is a read-only data source, so Terraform
# never creates, updates or deletes the repository or its images.
data "aws_ecr_repository" "app" {
  name = var.ecr_repository_name
}

# Resolve the mutable tag to an immutable digest at plan time. Instances pull by
# digest, so a retagged image cannot silently change the running application.
data "aws_ecr_image" "app" {
  repository_name = var.ecr_repository_name
  image_tag       = var.image_tag
}
