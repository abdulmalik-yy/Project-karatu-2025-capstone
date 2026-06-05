#--CLUSTER IAM ROLE--#
data "aws_iam_policy_document" "eks-cluster-assume-role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks-cluster-role" {
  name               = "eks-${var.eks_cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks-cluster-assume-role.json
  tags = {
    Name = "project-bedrock-eks-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-role.name
}

#--CLUSTER SECURITY GROUP--#
resource "aws_security_group" "eks-cluster-sg" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id
  tags = {
    Name = "eks-cluster-sg"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#--EKS CLUSTER--#
resource "aws_eks_cluster" "project-bedrock-cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks-cluster-role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks-cluster-sg.id]
  }

  tags = {
    Name = var.eks_cluster_name
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-policy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController
  ]
}


#--NODE IAM ROLE--#

data "aws_iam_policy_document" "eks-node-assume-role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks-node-role" {
  name               = "project-bedrock-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks-node-assume-role.json
  tags = {
    Name = "project-bedrock-eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-proxy-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-volumes-policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks-node-role.name
}

# SSM access so nodes can be connected via Session Manager
resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-dynamodb-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-s3-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-registry-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-role.name
}

#--NODE SECURITY GROUP--#
resource "aws_security_group" "eks-node-sg" {
  name        = "eks-node-sg"
  description = "Security group for EKS nodes"
  vpc_id      = var.vpc_id
  tags = {
    Name = "eks-node-sg"
  }

  #All traffic between nodes

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  #Allow control plane to node 

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks-cluster-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#--MANAGED NODE GROUP--#


resource "aws_eks_node_group" "project-bedrock-node-group" {
  cluster_name    = aws_eks_cluster.project-bedrock-cluster.name
  node_group_name = "project-bedrock-node-group"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.small"]
  disk_size       = 20
  tags = {
    Name = "project-bedrock-node-group"
  }

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-node-policy,
    aws_iam_role_policy_attachment.eks-node-proxy-policy,
    aws_iam_role_policy_attachment.eks-node-volumes-policy,
    aws_iam_role_policy_attachment.eks-node-registry-policy,
    aws_iam_role_policy_attachment.node_AmazonSSMManagedInstanceCore
  ]
}

resource "aws_launch_template" "nodes" {
  name_prefix            = "eks-node-template-prod"
  vpc_security_group_ids = [aws_security_group.eks-node-sg.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node-template-prod"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }
}

#--OIDC PROVIDER FOR EKS--#
data "tls_certificate" "eks" {
  url = aws_eks_cluster.project-bedrock-cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.project-bedrock-cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
}

#--CORE EKS ADD-ONS --#
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.project-bedrock-cluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_iam_openid_connect_provider.eks]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.project-bedrock-cluster.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_iam_openid_connect_provider.eks]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.project-bedrock-cluster.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_iam_openid_connect_provider.eks]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.project-bedrock-cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi_irsa_role.arn
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_iam_openid_connect_provider.eks]
}


#--EBS CSI IRSA ROLE--#
data "aws_iam_policy_document" "ebs_csi_irsa_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_irsa_role" {
  name               = "project-bedrock-ebs-csi-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_irsa_role.json
  tags = {
    Name = "project-bedrock-ebs-csi-irsa-role"
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_irsa_role_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_irsa_role.name
}


