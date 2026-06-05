output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.project-bedrock-cluster.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.project-bedrock-cluster.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.project-bedrock-cluster.certificate_authority[0].data
}

output "node_group_name" {
  description = "Name of the managed node group"
  value       = aws_eks_node_group.project-bedrock-node-group.node_group_name
}

output "node_group_arn" {
  description = "ARN of the managed node group"
  value       = aws_eks_node_group.project-bedrock-node-group.arn
}

output "eks_node_role_arn" {
  description = "ARN of the IAM role for EKS worker nodes"
  value       = aws_iam_role.eks-node-role.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL for EKS cluster"
  value       = aws_iam_openid_connect_provider.eks.url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for EKS cluster"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "eks_node_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  value       = aws_security_group.eks-node-sg.id
}