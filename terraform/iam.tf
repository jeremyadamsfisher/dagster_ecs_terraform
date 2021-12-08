resource "aws_iam_role" "ecs_dagster" {
  name               = "ecs_dagster"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_dagster.json
  inline_policy {
    name   = "dagster-inline-policy"
    policy = data.aws_iam_policy_document.inline_policy_dagster.json
  }
  tags = {
    Name = "ecs-dagster-iam-role"
  }
}

data "aws_iam_policy_document" "inline_policy_dagster" {
  // allow access to bucket for storing intermediary artifacts
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["*"]
  }
  // allow port forwaring through ssm
  // see: https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-add-permissions-to-existing-profile.html
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
  statement {
    actions   = ["s3:GetEncryptionConfiguration"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role_policy_dagster" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_dagster" {
  role       = aws_iam_role.ecs_dagster.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_dagster_ssm1" {
  role       = aws_iam_role.ecs_dagster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecs_dagster_ssm2" {
  role       = aws_iam_role.ecs_dagster.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "ecs_dagster" {
  name = "ecs_dagster"
  role = aws_iam_role.ecs_dagster.name
}

