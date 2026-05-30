# EKS Infrastructure Deployment

## Features

VPC
Private and Public subnets
Nat Gateway
VPC Endpoints
Bastion Host
Cluster Autoscaler IAM role

## Node Groups

EKS Managed Node Groups
Support for Graviton instances
Autoscaling Configuration
On-Demand Node Groups

## Add-ons

vpc-cni
coredns
kube-proxy
amazon-cloudwatch-observability

## Security

IAM least privilege policies
Security Groups
IAM Roles for Kubernetes workloads
Kubernetes RBAC integration

## Observability

Control plane logs
Container Insights support

## Prerequisites

Tool	         Version
Terraform	      >= 1.5.7, < 2.0.0
AWS Provider    >=6.0.0, < 7.0.0

## Repository Structure
.
├── eks.tf
├── network.tf
├── bastion_host.tf
├── cluster_autoscaler_irsa.tf
├── variables.tf
├── outputs.tf
├── versions.tf
│
├── modules/
│   ├── eks/
│   └── vpc/
│
└── README.md

## Quick Start
1. Clone Repository

```bash
git clone https://github.com/crifeboss/eks-module.git
cd eks-module
```

2. Configure Variables

Example:
```terraform
module "eks-lab" {
  source = "../git-folder/eks-module"

  cluster_name          = "eks-lab"
  eks_version           = "1.34"
  availability_zones   = ["us-east-2a","us-east-2b","us-east-2c"]
  region                = "us-east-2"
  vpc_id                = "192.168.1.0/24"
  public_subnet_cidr    = ["192.168.1.0/27"]
  private_subnet_cidrs = [
    "192.168.1.32/27",
    "192.168.1.64/27",
    "192.168.1.96/27"
  ]
}

output "cluster_autoscaler_irsa" {
  value = module.network.cluster_autoscaler_rolearn
}
```

3. Initialize Terraform
```bash
terraform init
```

4. Review Plan
```bash
terraform plan
```

5. Deploy
```bash
terraform apply
```

## Input Variables

| Variable        | Description        | Default          |
| --------------- | ------------------ | ---------------- |
| cluster_name    | EKS cluster name   | n/a              |
| cluster_version | Kubernetes version | latest supported |
| environment     | Environment name   | dev              |

## Networking

| Variable        | Description         |
| --------------- | ------------------- |
| vpc_id          | Existing VPC        |
| subnet_ids      | Worker node subnets |
| private_subnets | Private subnet list |
| public_subnets  | Public subnet list  |

## Outputs

| Output                    | Description      |
| ------------------------- | ---------------- |
| cluster_name              | EKS cluster name |
| cluster_endpoint          | API endpoint     |
| cluster_security_group_id | Security group   |
| oidc_provider_arn         | OIDC ARN         |
| nodegroup_arns            | Node group ARNs  |

Accessing the Cluster
```bash
aws eks update-kubeconfig --region us-east-2 --name demo-eks
```

Verify:
```bash
kubectl get nodes
```

Cluster Autoscaler
If enabled:
```bash
kubectl get deployment -n kube-system cluster-autoscaler
```

## Best Practices
Use private subnets for worker nodes
Prefer Graviton instances for cost optimization
Enable IRSA for AWS service access
Store Terraform state in S3 with DynamoDB locking
Use Karpenter instead of Cluster Autoscaler for large clusters
Pin Terraform module versions
Enable CloudWatch logging
Separate environments using dedicated state files