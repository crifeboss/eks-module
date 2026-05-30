resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "cluster-autoscaler-policy"
  description = "Cluster Autoscaler permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name = "cluster-autoscaler-role"
  attach_cluster_autoscaler_policy = true

  policies = {
    policy = aws_iam_policy.cluster_autoscaler_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}
