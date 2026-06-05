#--CLOUDWATCH LOG GROUP FOR EKS--#

resource "aws_cloudwatch_log_group" "project-bedrock-eks-cluster-logs" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 30
  kms_key_id        = "alias/aws/logs"
  tags = {
    Name = "project-bedrock-eks-cluster-logs"
  }
}

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/eks/${var.eks_cluster_name}/application"
  retention_in_days = 14
  tags = {
    Name = "project-bedrock-application-logs"
  }
}

resource "aws_cloudwatch_log_group" "dataplane_logs" {
  name              = "/aws/eks/${var.eks_cluster_name}/dataplane"
  retention_in_days = 14
  tags = {
    Name = "project-bedrock-dataplane-logs"
  }
}

#--IRSA ROLE FOR CLOUDWATCH AGENT--#
data "aws_iam_policy_document" "cwagent_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cwagent_role" {
  name               = "project-bedrock-cwagent-role"
  assume_role_policy = data.aws_iam_policy_document.cwagent_assume.json
  tags = {
    Name = "project-bedrock-cwagent-role"
  }
}

resource "aws_iam_role_policy_attachment" "cwagent_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cwagent_role.name
}

#allow cloudwatch agent to write logs to cloudwatch logs
resource "aws_iam_role_policy_attachment" "cw_logs_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = aws_iam_role.cwagent_role.name
}

#cloudwatch observability for eks add-ONS
resource "aws_eks_addon" "observability" {
  cluster_name                = var.eks_cluster_name
  addon_name                  = "cloudwatch-observability"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.cwagent_role.arn
  tags = {
    Name = "project-bedrock-cloudwatch-observability"
  }
}

#--IAM USER--#

#dev user
resource "aws_iam_user" "dev" {
  name = "bedrock-dev-view"
  path = "/system/bedrock/"

  tags = {
    Name = "bedrock-dev-view"
  }
}

#console login profile with auto-genetrated password
resource "aws_iam_user_login_profile" "dev" {
  user                    = aws_iam_user.dev.name
  password_reset_required = false
}

#programmatic access keys
resource "aws_iam_access_key" "dev" {
  user = aws_iam_user.dev.name
}

#--AWS console: read-only access--#
resource "aws_iam_user_policy_attachment" "readonly" {
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  user       = aws_iam_user.dev.name
}

#--S3 PutObject on access bucket --#
resource "aws_iam_user_policy" "s3_put" {
  name = "bedrock-dev-s3put"
  user = aws_iam_user.dev.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::bedrock-assets-alt-soe-025-350/*"
      }
    ]
  })
}

#--EKS ACCESS ENTRY: view ClusterRole --#
resource "aws_eks_access_entry" "dev" {
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_user.dev.arn
  type          = "STANDARD"
  tags = {
    Name = "bedrock-dev-access-entry"
  }
}

resource "aws_eks_access_policy_association" "dev_view" {
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/view-cluster"
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_user.dev.arn

  access_scope {
    type = "cluster"
  }
  depends_on = [
    aws_eks_access_entry.dev
  ]
}


















