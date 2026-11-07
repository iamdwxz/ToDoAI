variable "aws_region" {
  description = "AWS region where all resources are created."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Short project name used as a prefix for resource names."
  type        = string
  default     = "todoai"
}

variable "environment" {
  description = "Environment name used for tagging."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Exactly two public subnet CIDR blocks, one per Availability Zone."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Provide exactly two public subnet CIDR blocks."
  }
}

variable "ecr_repository_name" {
  description = "Name of the pre-existing ECR repository. It is referenced, never created."
  type        = string
  default     = "todoai"
}

variable "image_tag" {
  description = "Existing ECR tag resolved to an immutable digest for EC2 instances."
  type        = string
  default     = "1.0"

  validation {
    condition     = length(trimspace(var.image_tag)) > 0
    error_message = "image_tag must not be empty."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group."
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances."
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances."
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances."
  type        = number
  default     = 2
}

variable "cpu_target_utilization" {
  description = "Target average CPU utilization percentage for target tracking."
  type        = number
  default     = 60

  validation {
    condition     = var.cpu_target_utilization > 0 && var.cpu_target_utilization <= 100
    error_message = "cpu_target_utilization must be greater than 0 and at most 100."
  }
}

variable "health_check_path" {
  description = "HTTP path used by the ALB target group health check."
  type        = string
  default     = "/"
}

variable "domain_name" {
  description = "Public domain served by the ALB."
  type        = string
  default     = "todoaidb.pp.ua"
}

variable "create_route53_zone" {
  description = "Create the Route 53 hosted zone. Set to false to use an existing zone in the same account."
  type        = bool
  default     = true
}

variable "enable_https" {
  description = <<-EOT
    Create the ACM certificate, DNS validation records, validation waiter,
    HTTPS listener and port 443 rules.
    Keep this false until the Route 53 hosted zone is authoritative for the domain
    (its NS records are delegated at the parent DNS provider). Enabling it too early
    starts a 72-hour ACM validation window that cannot succeed.
  EOT
  type        = bool
  default     = false
}
