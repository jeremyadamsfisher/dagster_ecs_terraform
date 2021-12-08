# Dagster ECS Terraform

This project demonstrates running Dagster on ECS by leveraging Terraform

It can also be run locally:

```bash
pip install -r requirements-dagster.txt
dagit
```

## Deployment

```
cd terraform
terraform init
terraform apply
```

This should handle the docker build, etc. It takes a while! (Mostly to spin up a database.)

## ECS notes

I find the ECS interface pretty bare-bones, so there's a lot that needs to be added by hand. One thing that is particularly unintuitive is IAM for the dagster workers. For reference:

- **ECS** requests a instance from the...
- **auto-scaling group**, which determines the instance to launch by using the...
- **launch template**, which contains an IAM section within its...
- **instance profile**, which has one or more...
- **IAM roles**

## TODO

[ ] Any non-trivial pipeline needs an IO manager backed by a bucket. I wrote the IAM permissions allow access to all buckets for this reason, but it should really only have access to one bucket (which I don't even have in the terraform...)
