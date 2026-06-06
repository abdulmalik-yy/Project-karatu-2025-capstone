#=============================================================
# prod/outputs.tf
# These are the values Terraform will print after apply.
# They are also used by GitHub Actions to configure kubectl.
#=============================================================

output "db_password" {
  description = "The database password"
  value       = module.data.mysql_password
  sensitive   = true
}

output "bedrock_dev_password" {
  description = "The password for the bedrock-dev-view IAM user"
  value       = nonsensitive(module.monitoring.bedrock_dev_password)
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.compute.eks_cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster"
  value       = module.compute.eks_cluster_endpoint
}

output "configure_kubectl" {
  description = "Run this command to configure kubectl to talk to your cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}

output "assets_bucket_name" {
  description = "S3 bucket used for product image uploads"
  value       = "bedrock-assets-${var.student_id}"
}

output "mysql_secret_arn" {
  description = "ARN of the Secrets Manager secret holding MySQL credentials"
  value       = module.data.mysql_secret_arn
}

output "postgres_secret_arn" {
  description = "ARN of the Secrets Manager secret holding PostgreSQL credentials"
  value       = module.data.postgres_secret_arn
}

output "lbc_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller"
  value       = module.k8s_addons.lbc_role_arn
}
