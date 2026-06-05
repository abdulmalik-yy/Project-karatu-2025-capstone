variable "app_namespace" {
  description = "Kubernetes namespace name for the retail application"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the EKS cluster resides"
  type        = string
}

variable "cluster_oidc_arn" {
  description = "OIDC provider ARN for the EKS cluster (used for IRSA)"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "mysql_endpoint" { type = string }
variable "mysql_port" { type = number }
variable "mysql_username" { type = string }
variable "mysql_password" {
  type      = string
  sensitive = true
}

variable "postgres_endpoint" { type = string }
variable "postgres_port" { type = number }
variable "postgres_username" { type = string }
variable "postgres_password" {
  type      = string
  sensitive = true
}

variable "redis_endpoint" { type = string }
variable "redis_port" { type = number }

variable "dynamodb_table_name" { type = string }
