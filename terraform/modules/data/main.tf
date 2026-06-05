data "aws_caller_identity" "current" {}

#--DATABASE SUBNETS: PRIVATE--#
resource "aws_db_subnet_group" "database-subnet-group" {
  name       = "database-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "database-subnet-group"
  }
}

#--DATABASE SECURITY GROUP:MySQL--#
resource "aws_security_group" "database-security-group" {
  name        = "database-security-group"
  description = "Security group for MySQL instances"
  vpc_id      = var.vpc_id
  tags = {
    Name = "database-security-group"
  }

  # Ingress rule: Allow MySQL from EKS nodes
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_node_security_group_id]
  }

  # Egress rule: Allow all to the Internet (for patching, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#--DATABASE SECURITY GROUP:PostgreSQL--#
resource "aws_security_group" "database-security-group-rds" {
  name        = "database-security-group-rds"
  description = "Security group for RDS instances"
  vpc_id      = var.vpc_id
  tags = {
    Name = "database-security-group-rds"
  }

  # Ingress rule: Allow MySQL from EKS nodes
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_node_security_group_id]
  }

  # Egress rule: Allow all to the Internet (for patching, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#--RANDOM PASSWORDS FOR RDS INSTANCES--#

resource "random_password" "mysql_password" {
  length  = 24
  special = true
}

resource "random_password" "postgres_password" {
  length  = 24
  special = true
}

#--SECRETS MANAGER:MySQL--#

resource "aws_secretsmanager_secret" "mysql" {
  name        = "project-bedrock/mysql"
  description = "MySQL RDS credentials"
}

resource "aws_secretsmanager_secret_version" "mysql" {
  secret_id = aws_secretsmanager_secret.mysql.id
  secret_string = jsonencode({
    username = "catalog_user"
    password = random_password.mysql_password.result
    host     = aws_db_instance.mysql.address
    port     = 3306
    dbname   = "catalog"
    engine   = "mysql"
  })
}

#--SECRETS MANAGER:PostgreSQL--#

resource "aws_secretsmanager_secret" "postgres" {
  name        = "project-bedrock/postgres"
  description = "PostgreSQL RDS credentials"
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode({
    username = "orders_user"
    password = random_password.postgres_password.result
    host     = aws_db_instance.postgres.address
    port     = 5432
    dbname   = "orders"
    engine   = "postgres"
  })
}

#--PARAMETER GROUP--#

#MySQL
resource "aws_db_parameter_group" "mysql" {
  name        = "project-bedrock-mysql"
  description = "Parameter group for MySQL instances"
  family      = "mysql8.0"
  tags = {
    Name = "project-bedrock-mysql"
  }
}

#PostgreSQL
resource "aws_db_parameter_group" "postgres" {
  name        = "project-bedrock-postgres"
  description = "Parameter group for PostgreSQL instances"
  family      = "postgres15"
  tags = {
    Name = "project-bedrock-postgres"
  }
}

#--RDS INSTANCE:MySQL--#
resource "aws_db_instance" "mysql" {
  identifier              = "project-bedrock-mysql"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  max_allocated_storage   = 100
  username                = "catalog_user"
  password                = random_password.mysql_password.result
  db_name                 = "catalog"
  db_subnet_group_name    = aws_db_subnet_group.database-subnet-group.name
  vpc_security_group_ids  = [aws_security_group.database-security-group.id]
  parameter_group_name    = aws_db_parameter_group.mysql.name
  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 0
  multi_az                = false
  tags = {
    Name = "project-bedrock-mysql-instance"
  }
}

#--RDS INSTANCE:PostgreSQL--#
resource "aws_db_instance" "postgres" {
  identifier              = "project-bedrock-postgres"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp3"
  max_allocated_storage   = 100
  username                = "orders_user"
  password                = random_password.postgres_password.result
  db_name                 = "orders"
  db_subnet_group_name    = aws_db_subnet_group.database-subnet-group.name
  vpc_security_group_ids  = [aws_security_group.database-security-group-rds.id]
  parameter_group_name    = aws_db_parameter_group.postgres.name
  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 0
  multi_az                = false
  tags = {
    Name = "project-bedrock-postgres-instance"
  }
}
#--ELASTICACHE (Redis) CLUSTER--#
resource "aws_elasticache_subnet_group" "redis_subnet_grp" {
  name       = "project-bedrock-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "project-bedrock-redis-subnet-group"
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "project-bedrock-redis-sg"
  description = "Security group for Redis cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-bedrock-redis-sg"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id         = "project-bedrock-redis"
  engine             = "redis"
  node_type          = "cache.t3.micro"
  num_cache_nodes    = 1
  subnet_group_name  = aws_elasticache_subnet_group.redis_subnet_grp.name
  security_group_ids = [aws_security_group.redis_sg.id]
  engine_version     = "6.x"
  port               = 6379

  tags = {
    Name = "project-bedrock-redis"
  }
}

resource "aws_secretsmanager_secret" "redis" {
  name        = "project-bedrock/redis"
  description = "Optional Redis AUTH password"
}

