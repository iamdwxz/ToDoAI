terraform {
  # Terraform 1.6+ is required for the provider and validation features used here.
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State is intentionally local for this deployment.
  # The generated terraform.tfstate must never be committed or shared.
}
