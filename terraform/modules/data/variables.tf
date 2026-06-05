variable "vpc_id" {
  description = "VPC ID where the RDS and ElastiCache resources will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS subnet group and ElastiCache subnet group"
  type        = list(string)
}

variable "eks_node_security_group_id" {
  description = "Security group ID of EKS nodes to allow connection to databases"
  type        = string
}
