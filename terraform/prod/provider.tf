
#--PROVIDER--#
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}
provider "aws" {
  region  = "us-east-1"

  default_tags {
    tags = {
      Project = "karatu-2025-capstone"
    }
  }
}

#kubernetes provider
provider "kubernetes" {
  host                   = module.compute.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.compute.eks_cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.compute.eks_cluster_name,
      "--region",
      var.region
    ]
  }
}

#helm provider
provider "helm" {
  kubernetes {
    host                   = module.compute.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.compute.eks_cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.compute.eks_cluster_name,
        "--region",
        var.region
      ]
    }
  }
}
