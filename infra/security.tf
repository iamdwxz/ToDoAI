# ALB security group: accepts public HTTP traffic and, when enabled, HTTPS traffic.
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb"
  description = "Ingress for the public Application Load Balancer"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_ipv4" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet (redirected to HTTPS when enabled)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# The HTTPS rule only exists when the certificate has been validated successfully.
resource "aws_vpc_security_group_ingress_rule" "alb_https_ipv4" {
  count = var.enable_https ? 1 : 0

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# Security groups are stateful, so response traffic to clients needs no egress rule.
# The ALB only needs egress to the nginx targets on port 80.
resource "aws_vpc_security_group_egress_rule" "alb_to_instances" {
  security_group_id            = aws_security_group.alb.id
  description                  = "ALB traffic to nginx targets only"
  referenced_security_group_id = aws_security_group.instance.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# EC2 security group: no direct internet ingress. Only the ALB may reach nginx on port 80.
resource "aws_security_group" "instance" {
  name        = "${local.name_prefix}-instance"
  description = "Ingress from the ALB only; egress for ECR, S3, SSM and DNS"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-instance"
  }
}

resource "aws_vpc_security_group_ingress_rule" "instance_http_from_alb" {
  security_group_id            = aws_security_group.instance.id
  description                  = "HTTP from the ALB security group only"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# Egress is unrestricted because there is no NAT Gateway: instances need to reach
# ECR, S3, SSM and CloudWatch endpoints over the Internet Gateway.
resource "aws_vpc_security_group_egress_rule" "instance_all" {
  security_group_id = aws_security_group.instance.id
  description       = "Outbound to ECR, S3, SSM and DNS over the Internet Gateway"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
