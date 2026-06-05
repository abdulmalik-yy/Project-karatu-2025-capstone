#=============================================================
# prod/main.tf
# This file wires all modules together.
# Think of it like a "master switchboard" -- each module is
# a building block, and here we connect them in the right order.
#=============================================================

# -- 1. NETWORK ------------------------------------------------
# Creates the VPC, subnets, internet gateway, NAT gateway, etc.
module "network" {
  source = "../modules/network"

  vpc_name               = var.vpc_name
  vpc_cidr               = "10.0.0.0/16"
  public_subnet_01_cidr  = "10.0.1.0/24"
  public_subnet_02_cidr  = "10.0.2.0/24"
  private_subnet_01_cidr = "10.0.3.0/24"
  private_subnet_02_cidr = "10.0.4.0/24"
  availability_zone_1    = "us-east-1a"
  availability_zone_2    = "us-east-1b"
  eks_cluster_name       = var.cluster_name
}

# -- 2. COMPUTE (EKS) -----------------------------------------
# Creates the EKS control plane, node group, and OIDC provider.
# It NEEDS the VPC and subnet IDs from the network module above.
module "compute" {
  source = "../modules/compute"

  eks_cluster_name   = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
}

# -- 3. MONITORING (CloudWatch) --------------------------------
# Creates CloudWatch Log Groups and the CloudWatch Agent IAM role.
# Needs the OIDC provider details from the compute module.
module "monitoring" {
  source = "../modules/monitoring"

  eks_cluster_name  = var.cluster_name
  oidc_provider_arn = module.compute.oidc_provider_arn
  oidc_provider_url = module.compute.oidc_provider_url

  depends_on = [module.compute]
}

# -- 4. STORAGE (S3 + Lambda) ----------------------------------
# Creates the private S3 bucket for product images and the Lambda
# function that gets triggered when a file is uploaded.
module "storage" {
  source = "../modules/storage"

  bucket_name = "bedrock-assets-${var.student_id}"
}

# -- 5. DATA (RDS MySQL + PostgreSQL + Redis ElastiCache) ------
# Creates managed databases in PRIVATE subnets for security.
# Apps inside EKS connect to these via private DNS names.
module "data" {
  source = "../modules/data"

  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  eks_node_security_group_id = module.compute.eks_node_security_group_id

  depends_on = [module.network, module.compute]
}

# -- 6. DYNAMODB -----------------------------------------------
# Creates DynamoDB tables for the shopping cart / orders service.
module "dynamodb" {
  source = "../modules/dynamodb"

  table_name     = "project-bedrock-cart"
  hash_key       = "cartId"
  billing_mode   = "PAY_PER_REQUEST"
  read_capacity  = 0
  write_capacity = 0
}

# -- 7. K8S-ADDONS ---------------------------------------------
# Creates IAM role for the AWS Load Balancer Controller (IRSA)
# and the retail-app namespace via the kubernetes provider.
# This must run AFTER the cluster is ready.
module "k8s_addons" {
  source = "../modules/k8s-addons"

  eks_cluster_name = var.cluster_name
  aws_region       = var.region
  cluster_oidc_arn = module.compute.oidc_provider_arn
  app_namespace    = var.application_namespace
  vpc_id           = module.network.vpc_id

  mysql_endpoint      = module.data.mysql_endpoint
  mysql_port          = module.data.mysql_port
  mysql_username      = module.data.mysql_username
  mysql_password      = module.data.mysql_password
  postgres_endpoint   = module.data.postgres_endpoint
  postgres_port       = module.data.postgres_port
  postgres_username   = module.data.postgres_username
  postgres_password   = module.data.postgres_password
  redis_endpoint      = module.data.redis_endpoint
  redis_port          = module.data.redis_port
  dynamodb_table_name = module.dynamodb.table_name

  depends_on = [module.compute, module.data, module.dynamodb]
}
