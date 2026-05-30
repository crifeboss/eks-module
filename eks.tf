module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  region             = var.region
  kubernetes_version = var.eks_version

  addons = {
    coredns                = {
      most_recent = true
    }
    kube-proxy             = {
      most_recent = true
    }
    vpc-cni                = {
      before_compute = true
      most_recent = true
    }
    amazon-cloudwatch-observability = {
      most_recent = true
    }
  }

  # Optional
  endpoint_public_access = false
  endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true
  cloudwatch_log_group_retention_in_days = 30

  vpc_id                   = aws_vpc.eks.id
  subnet_ids               = aws_subnet.private[*].id

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    ng01 = {
      ami_type       = "AL2023_ARM_64_STANDARD"
      instance_types = ["t4g.medium"]

      min_size     = 1
      max_size     = 1
      desired_size = 1

      capacity_type = "ON_DEMAND"
      iam_role_additional_policies = {
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        cloudwatch = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      }
      tags = {
      "k8s.io/cluster-autoscaler/enabled"               = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}"  = "owned"
      }
    }
  }

  access_entries = {
    admin = {
      principal_arn = aws_iam_role.bastion.arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  security_group_additional_rules = {
    bastion_https = {
      description              = "Allow Bastion to EKS API"
      protocol                 = "tcp"
      from_port                = 443
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = aws_security_group.bastion.id
    }
  }

  tags = {
    Environment = "lab"
    Terraform   = "true"
  }
}
