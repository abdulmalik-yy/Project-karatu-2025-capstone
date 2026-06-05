output "mysql_endpoint" {
  value = aws_db_instance.mysql.address
}

output "mysql_port" {
  value = aws_db_instance.mysql.port
}

output "mysql_secret_arn" {
  value = aws_secretsmanager_secret.mysql.arn
}

output "mysql_username" {
  value = "catalog_user"
}

output "mysql_password" {
  value     = random_password.mysql_password.result
  sensitive = true
}

output "postgres_endpoint" {
  value = aws_db_instance.postgres.address
}

output "postgres_port" {
  value = aws_db_instance.postgres.port
}

output "postgres_secret_arn" {
  value = aws_secretsmanager_secret.postgres.arn
}

output "postgres_username" {
  value = "orders_user"
}

output "postgres_password" {
  value     = random_password.postgres_password.result
  sensitive = true
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