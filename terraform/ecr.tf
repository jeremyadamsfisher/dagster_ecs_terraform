module "ecr_dagit" {
  source = "lgallard/ecr/aws"
  name   = "ecr_dagit"
}

module "ecr_dagster_pipeline" {
  source = "lgallard/ecr/aws"
  name   = "ecr_dagster_pipeline"
}

resource "null_resource" "upload_to_ecr" {
  provisioner "local-exec" {
    command = <<EOF
    docker build -f ../Dockerfile.dagster -t ${module.ecr_dagit.repository_url}:latest ..
    docker build -f ../Dockerfile.pipelines \
      --build-args USER_WORKSPACE={var.grpc_hostname} \
      -t ${module.ecr_dagster_pipeline.repository_url}:latest ..
    echo ${var.aws_ecr_password} \
    | docker login \
      --username AWS \
      --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com
    docker push ${module.ecr_dagit.repository_url}:latest
    docker push ${module.ecr_dagster_pipeline.repository_url}:latest
    EOF
  }
  triggers = {
    always_run = timestamp()
  }
}
