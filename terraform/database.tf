resource "aws_security_group" "pg" {
  name   = "dagster-db"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "pg" {
  name = "dagster-db"
  subnet_ids = [
    var.subnet_id_1,
    var.subnet_id_2,
  ]
}

resource "aws_db_parameter_group" "pg" {
  name   = "dagster-db"
  family = "postgres13"
  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "pg" {
  identifier             = "dagster-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "13.1"
  username               = var.dagster_postgres_username
  password               = var.dagster_postgres_password
  db_subnet_group_name   = aws_db_subnet_group.pg.name
  vpc_security_group_ids = [aws_security_group.pg.id]
  parameter_group_name   = aws_db_parameter_group.pg.name
  publicly_accessible    = false
  skip_final_snapshot    = true
}
