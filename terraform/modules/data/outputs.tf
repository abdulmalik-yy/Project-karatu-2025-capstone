output "mysql_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "mysql_port" {
  value = aws_db_instance.mysql.port
}

output "mysql_secret_arn" {
  value = aws_secretsmanager_secret.mysql.arn
}

output "postgres_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "postgres_port" {
  value = aws_db_instance.postgres.port
}

output "postgres_secret_arn" {
  value = aws_secretsmanager_secret.postgres.arn
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].port
}

output "redis_secret_arn" {
  value = aws_secretsmanager_secret.redis.arn
}