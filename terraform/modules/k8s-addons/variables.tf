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
