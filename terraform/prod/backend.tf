#-- Terraform Backend--#

terraform {
  backend "s3" {
    bucket  = "bedrock-tfstate-alt-soe-025-350"
    key     = "project-bedrock/terraform.tfstate"
    region  = "us-east-1"
  }
}
