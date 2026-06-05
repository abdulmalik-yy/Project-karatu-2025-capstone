
#--PROVIDER--#
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region  = "us-east-1"
  profile = "abdulmalik_aws"

  default_tags {
    tags = {
      project = "karatu-2025-capstone"
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
      var.region,
      "--profile",
      "abdulmalik_aws"
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
        var.region,
        "--profile",
        "abdulmalik_aws"
      ]
    }
  }
}
