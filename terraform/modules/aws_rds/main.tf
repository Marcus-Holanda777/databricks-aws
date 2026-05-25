resource "aws_db_instance" "postgres_db" {
  identifier            = "mvsh-postgres-${var.environment}"
  engine                = "postgres"
  engine_version        = "15"
  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"
  region                = var.aws_region

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = var.postgres_subnets_name
  vpc_security_group_ids = [var.postgres_security_group_id]

  publicly_accessible = false
  skip_final_snapshot = true
  multi_az            = var.multi_az_nat

  tags = merge(
    {
      Name        = "mvsh-postgres-${var.environment}",
      Environment = var.environment,
      Component   = "Database",
    },
    var.tags,
  )
}