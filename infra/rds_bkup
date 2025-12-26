terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-db-credentials-${random_id.suffix.hex}"
  description = "Credentials for Aurora PostgreSQL cluster"
  
  tags = local.common_tags
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for Aurora PostgresSQL"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    description = "Access from EKS private subnets only"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
  
  tags = local.common_tags
}

resource "aws_rds_cluster" "aurora_postgresql" {
  cluster_identifier     = "${var.project_name}-db"
  engine                 = "aurora-postgresql"
  engine_version         = var.db_engine_version
  engine_mode            = "provisioned"
  database_name          = "n8ndb"
  master_username        = "n8nadmin"
  master_password        = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  serverlessv2_scaling_configuration {
    min_capacity = var.db_min_capacity
    max_capacity = var.db_max_capacity
  }
  
  skip_final_snapshot     = true
  backup_retention_period = 7
  storage_encrypted       = true
  
  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  identifier         = "${var.project_name}-db-instance"
  cluster_identifier = aws_rds_cluster.aurora_postgresql.id
  instance_class     = "db.serverless"
  engine             = "aurora-postgresql"
  engine_version     = var.db_engine_version
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = aws_rds_cluster.aurora_postgresql.master_username
    password = random_password.db_password.result
    engine   = "postgresql"
    host     = aws_rds_cluster.aurora_postgresql.endpoint
    port     = 5432
    dbname   = aws_rds_cluster.aurora_postgresql.database_name
  })
}