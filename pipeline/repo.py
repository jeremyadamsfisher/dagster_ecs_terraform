from dagster import repository
from example_job import hello_dagster_job

@repository
def my_repository():
    return [hello_dagster_job]

