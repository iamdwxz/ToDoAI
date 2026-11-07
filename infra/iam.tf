# Trust policy that allows EC2 instances to assume the role.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${local.name_prefix}-ec2-role"
  description        = "Allows ToDoAI EC2 instances to pull from ECR and use SSM"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Least-privilege ECR pull policy scoped to the existing repository.
# GetAuthorizationToken must use "*"; the layer/image actions are repository-scoped.
data "aws_iam_policy_document" "ecr_read" {
  statement {
    sid       = "EcrAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPullTodoaiImage"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = [data.aws_ecr_repository.app.arn]
  }
}

resource "aws_iam_policy" "ecr_read" {
  name        = "${local.name_prefix}-ecr-read"
  description = "Pull the ToDoAI image from the existing ECR repository"
  policy      = data.aws_iam_policy_document.ecr_read.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ecr_read.arn
}

# SSM Session Manager provides shell access without opening SSH or storing keys.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2.name
}
