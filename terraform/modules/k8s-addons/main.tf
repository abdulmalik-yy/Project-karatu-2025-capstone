#--RETAIL-APP NAMESPACE--#
resource "kubernetes_namespace_v1" "retail_app" {
  metadata {
    name = var.app_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "project"                      = "bedrock"
    }
  }
}

#--IRSA ROLE FOR AWS LOAD BALANCER CONTROLLER--#
data "aws_iam_policy_document" "aws_lb_controller_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${element(split("oidc-provider/", var.cluster_oidc_arn), 1)}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${element(split("oidc-provider/", var.cluster_oidc_arn), 1)}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lbc" {
  name               = "${var.eks_cluster_name}-load-balancer-controller-role"
  assume_role_policy = data.aws_iam_policy_document.aws_lb_controller_assume_role.json
  tags = {
    Name = "${var.eks_cluster_name}-load-balancer-controller-role"
  }
}

# Official LBC IAM policy (fetched from the AWS LBC GitHub releases)
resource "aws_iam_policy" "lbc" {
  name        = "${var.eks_cluster_name}-load-balancer-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  #This is the official LBC policy from AWS LBC GitHub releases
  #https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
  policy = jsonencode({ "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "iam:CreateServiceLinkedRole"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "iam:AWSServiceName" : "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "ec2:GetSecurityGroupsForVpc",
          "ec2:DescribeIpamPools",
          "ec2:DescribeRouteTables",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTrustStores",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:DescribeCapacityReservation"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSecurityGroup"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "StringEquals" : {
            "ec2:CreateAction" : "CreateSecurityGroup"
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition" : {
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
          "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyListenerAttributes",
          "elasticloadbalancing:ModifyCapacityReservation",
          "elasticloadbalancing:ModifyIpPools"
        ],
        "Resource" : "*",
        "Condition" : {
          "Null" : {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:AddTags"
        ],
        "Resource" : [
          "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
          "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "elasticloadbalancing:CreateAction" : [
              "CreateTargetGroup",
              "CreateLoadBalancer"
            ]
          },
          "Null" : {
            "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        "Resource" : "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetRulePriorities"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lbc_attach" {
  policy_arn = aws_iam_policy.lbc.arn
  role       = aws_iam_role.lbc.name
}


#-- IRSA ROLE FOR CARTS (DynamoDB Access) --#
data "aws_iam_policy_document" "carts_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.cluster_oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${element(split("oidc-provider/", var.cluster_oidc_arn), 1)}:sub"
      values   = ["system:serviceaccount:${var.app_namespace}:carts"]
    }
    condition {
      test     = "StringEquals"
      variable = "${element(split("oidc-provider/", var.cluster_oidc_arn), 1)}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "carts_irsa" {
  name               = "${var.eks_cluster_name}-carts-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.carts_assume_role.json
}

resource "aws_iam_role_policy_attachment" "carts_dynamodb" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.carts_irsa.name
}


#-- HELM RELEASES --#

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lbc.arn
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }
}

resource "helm_release" "catalog" {
  name       = "catalog"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-catalog-chart"
  version    = "1.6.1"
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  set {
    name  = "app.persistence.provider"
    value = "mysql"
  }
  set {
    name  = "app.persistence.endpoint"
    value = "${var.mysql_endpoint}:${var.mysql_port}"
  }
  set {
    name  = "app.persistence.secret.username"
    value = var.mysql_username
  }
  set {
    name  = "app.persistence.secret.password"
    value = var.mysql_password
  }

  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "helm_release" "carts" {
  name       = "carts"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-cart-chart"
  version    = "1.6.1"
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  set {
    name  = "app.persistence.provider"
    value = "dynamodb"
  }
  set {
    name  = "app.persistence.dynamodb.tableName"
    value = var.dynamodb_table_name
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.carts_irsa.arn
  }

  depends_on = [helm_release.catalog]
}

resource "helm_release" "checkout" {
  name       = "checkout"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-checkout-chart"
  version    = "1.6.1"
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  set {
    name  = "app.persistence.provider"
    value = "redis"
  }
  set {
    name  = "app.persistence.redis.endpoint"
    value = "${var.redis_endpoint}:${var.redis_port}"
  }

  depends_on = [helm_release.carts]
}

resource "helm_release" "orders" {
  name       = "orders"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-orders-chart"
  version    = "1.6.1"
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  set {
    name  = "app.persistence.provider"
    value = "postgres"
  }
  set {
    name  = "app.persistence.endpoint"
    value = "${var.postgres_endpoint}:${var.postgres_port}"
  }
  set {
    name  = "app.persistence.database"
    value = "orders"
  }
  set {
    name  = "app.persistence.secret.username"
    value = var.postgres_username
  }
  set {
    name  = "app.persistence.secret.password"
    value = var.postgres_password
  }

  depends_on = [helm_release.checkout]
}

resource "helm_release" "ui" {
  name       = "ui"
  repository = "oci://public.ecr.aws/aws-containers"
  chart      = "retail-store-sample-ui-chart"
  version    = "1.6.1"
  namespace  = kubernetes_namespace_v1.retail_app.metadata[0].name

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  depends_on = [
    helm_release.orders
  ]
}


