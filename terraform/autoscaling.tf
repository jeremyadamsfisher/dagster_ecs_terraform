
resource "aws_security_group" "dagster_sg" {
  name   = "dagster_sg"
  vpc_id = 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_launch_template" "launch_template" {
  name_prefix   = "ecs_dagster_launch_config"
  image_id      = "ami-091aa67fccd794d5f" // aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended
  instance_type = "t3.small"
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_dagster.name
  }
  // Must be the same name as the ecs-cluster.name created
  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${var.ecs_dagster_cluster} >> /etc/ecs/ecs.config
EOF
  )
  // Updates require destroying orginal resource
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_db_instance.pg,
  ]
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.dagster_sg.id]
  }
}

resource "aws_autoscaling_group" "dagster_asg" {
  name = "dagster-asg"
  vpc_zone_identifier = [
    var.subset_id_1,
    var.subset_id_2,
  ]
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }
  force_delete              = true
  desired_capacity          = var.desired_capacity
  min_size                  = var.desired_capacity
  max_size                  = var.desired_capacity * 2
  health_check_grace_period = 60
  health_check_type         = "EC2"
  default_cooldown          = 10
  // This prevents all instances running tasks from being terminated during scale-in
  # protect_from_scale_in = var.protect_from_scale_in
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = "dagster_managed_vm"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "dagster_cp" {
  name = "dagster-capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.dagster_asg.arn
    managed_termination_protection = var.managed_termination_protection
    managed_scaling {
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 5
      instance_warmup_period    = 10
      status                    = "ENABLED"
      target_capacity           = var.target_capacity
    }
  }
}
