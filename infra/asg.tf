# Latest Amazon Linux 2023 AMI resolved through the public SSM parameter.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Launch template used by every ASG instance. The user_data script installs Docker,
# authenticates to ECR and starts the digest-pinned image.
resource "aws_launch_template" "app" {
  name                   = "${local.name_prefix}-lt"
  description            = "ToDoAI nginx container on Amazon Linux 2023"
  image_id               = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [aws_security_group.instance.id]

  # IMDSv2 is required to reduce the impact of SSRF-style credential theft.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    aws_region   = var.aws_region
    ecr_registry = local.ecr_registry
    image_uri    = local.image_uri
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.name_prefix}-app"
    }
  }

  tags = {
    Name = "${local.name_prefix}-lt"
  }
}

resource "aws_autoscaling_group" "app" {
  name = "${local.name_prefix}-asg"

  vpc_zone_identifier = aws_subnet.public[*].id

  min_size         = var.asg_min_size
  desired_capacity = var.asg_desired_capacity
  max_size         = var.asg_max_size

  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 600
  wait_for_capacity_timeout = "15m"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Replace running instances when the launch template changes (new image digest,
  # user_data change, AMI update). A rolling refresh keeps capacity available.
  # A launch_template change is always a refresh trigger, so no explicit triggers
  # argument is needed.
  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      max_healthy_percentage = 200
      instance_warmup        = 300
      auto_rollback          = true
    }
  }

  dynamic "tag" {
    for_each = local.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # Ensure public networking and the ALB listener exist before instances boot and
  # try to reach ECR, SSM and the target group.
  depends_on = [
    aws_internet_gateway.this,
    aws_route_table_association.public,
    aws_lb_listener.http,
  ]

  lifecycle {
    # Autoscaling owns capacity after creation; Terraform must not reset it to the
    # initial desired value on every apply.
    ignore_changes = [desired_capacity]

    precondition {
      condition     = var.asg_min_size <= var.asg_desired_capacity && var.asg_desired_capacity <= var.asg_max_size
      error_message = "ASG sizes must satisfy: min_size <= desired_capacity <= max_size."
    }
  }

  # No create_before_destroy: the ASG has a fixed name, so creating a replacement
  # before destroying the old group would collide. Rolling changes are handled by
  # instance_refresh above.
}

# Scale out when average CPU exceeds 60% and back in when it falls below.
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${local.name_prefix}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_utilization
  }
}
