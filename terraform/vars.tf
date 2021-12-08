var "vpc_id" {
  type = string
}

var "subnet_id_1" {
  type = string
}

var "subnet_id_2" {
  type = string
}

variable "dagster_postgres_username" {
  description = "dagster metadata storage db username"
  type        = string
  sensitive   = true
}

variable "dagster_postgres_password" {
  description = "dagster metadata storage db password"
  type        = string
  sensitive   = true
}

variable "ecs_dagster_cluster" {
  type    = string
  default = "ecs_dagster_cluster"
}

variable "managed_termination_protection" {
  default = "DISABLED"
}

variable "target_capacity" {
  default     = 100
  description = "Target utilization for the capacity provider. A number between 1 and 100."
}

variable "desired_capacity" {
  default = 1
}

variable "cache_buster" {
  default     = "16"
  description = "secrets, autoscaling groups and their capacity providers cannot be updated (https://github.com/aws/containers-roadmap/issues/632). Increment after changing settings in asg or cp."
}

variable "dagster_postgres_db_name" {
  default = "postgres"
}

variable "grpc_hostname" {
  default = "docker-pipelines"
}

variable "aws_ecr_password" {
  description = "determine with `aws ecr get-login-password --region us-east-1`"
}
