from dagster import op, job


@op
def hello_dagster(context):
    context.log.info("Hello, dagster!")


@job
def hello_dagster_job():
    hello_dagster()
