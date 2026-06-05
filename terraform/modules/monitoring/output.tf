output "cwagent_role_arn" {
  description = "ARN of the CloudWatch Agent IAM role"
  value       = aws_iam_role.cwagent_role.arn
}

output "eks_cluster_log_group_arn" {
  description = "ARN of the EKS cluster control‑plane CloudWatch log group"
  value       = aws_cloudwatch_log_group.project-bedrock-eks-cluster-logs.arn
}

output "application_log_group_arn" {
  description = "ARN of the application CloudWatch log group"
  value       = aws_cloudwatch_log_group.application_logs.arn
}

output "dataplane_log_group_arn" {
  description = "ARN of the dataplane CloudWatch log group"
  value       = aws_cloudwatch_log_group.dataplane_logs.arn
}