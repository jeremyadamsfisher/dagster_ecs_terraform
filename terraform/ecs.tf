locals {
  container_env_vars = [
    {
      name  = "DAGSTER_POSTGRES_HOSTNAME"
      value = aws_db_instance.pg.address
    },
    {
      name  = "DAGSTER_POSTGRES_USER"
      value = var.dagster_postgres_username
    },
    {
      name  = "DAGSTER_POSTGRES_PASSWORD"
      value = var.dagster_postgres_password
    },
    {
      name  = "DAGSTER_POSTGRES_DB"
      value = var.dagster_postgres_db_name
    },
    {
      name  = "DAGSTER_CURRENT_IMAGE"
      value = "${module.ecr_dagster_pipeline.repository_url}:latest"
    },
    {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    },
    {
      name  = "GRPC_HOSTNAME"
      value = var.grpc_hostname
    },
  ]
}

resource "aws_ecs_cluster" "dagster" {
  name               = var.ecs_dagster_cluster // must be the same given under ecs_dagster_launch_config.user_data
  capacity_providers = [aws_ecs_capacity_provider.dagster_cp.name]
  depends_on = [
    aws_db_instance.pg
  ]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.dagster_cp.name
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_task_definition" "dagster_task" {
  family             = "${var.ecs_dagster_cluster}-task"
  execution_role_arn = aws_iam_role.ecs_dagster.arn
  task_role_arn      = aws_iam_role.ecs_dagster.arn // task to have permissions
  network_mode       = "host"

  container_definitions = jsonencode([
    {
      name      = "dagit"
      image     = "${module.ecr_dagit.repository_url}:latest"
      cpu       = 512
      memory    = 512
      essential = true
      hostname  = "docker-dagit"
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = local.container_env_vars
      entryPoint  = ["dagit", "-h", "0.0.0.0", "-p", "3000", "-w", "workspace.yaml"]
      mount_points = [
        {
          containerPath = "/var/run/docker.sock"
          sourceVolume  = "docker_sock"
          readOnly      = true
        }
      ]
    },
    {
      name        = "daemon"
      image       = "${module.ecr_dagit.repository_url}:latest"
      cpu         = 512
      memory      = 1028
      essential   = true
      hostname    = "docker-daemon"
      environment = local.container_env_vars
      entryPoint  = ["dagster-daemon", "run"]
      mount_points = [
        {
          containerPath = "/var/run/docker.sock"
          sourceVolume  = "docker_sock"
          readOnly      = true
        }
      ]
    },
    {
      name        = "uptime"
      image       = "${module.ecr_dagster_pipeline.repository_url}:latest"
      cpu         = 256
      memory      = 256
      essential   = true
      hostname    = var.grpc_hostname
      environment = local.container_env_vars
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 4000
          hostPort      = 4000
        }
      ]
    }
  ])

  volume {
    host_path = "/var/run/docker.sock"
    name      = "docker_sock"
  }

  tags = {
    Name = "dagster-ecs-task-definition"
  }
  depends_on = [
    aws_db_instance.pg,
    null_resource.upload_to_ecr
  ]
}

resource "aws_ecs_service" "dagster" {
  name            = var.ecs_dagster_cluster
  cluster         = aws_ecs_cluster.dagster.id
  task_definition = aws_ecs_task_definition.dagster_task.arn
  desired_count   = 1
  depends_on = [
    aws_db_instance.pg
  ]
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.dagster_cp.name
    weight            = 100
  }
}
