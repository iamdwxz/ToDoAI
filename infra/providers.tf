provider "aws" {
  region = var.aws_region

  # Apply the shared tags to every resource that supports tagging.
  default_tags {
    tags = local.common_tags
  }
}
