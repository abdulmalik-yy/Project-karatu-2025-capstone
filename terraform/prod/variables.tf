variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  default     = "project-bedrock-vpc"
}

variable "cluster_name" {
  description = "Name of the cluster"
  default     = "project-bedrock-cluster"
}

variable "cluster_version" {
  description = "EKS cluster version"
  default     = "1.34"
}

variable "application_namespace" {
  description = "Namespace for the application"
  default     = "retail-app"
}

variable "iam_username" {
  description = "Username for IAM user"
  default     = "bedrock-dev-view"

}

variable "student_id" {
  description = "ID number"
  default     = "alt-soe-2025-350"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}
    