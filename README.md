# EKS Infrastructure Deployment

## Features

- Private and Public subnets
- Nat Gateway
- VPC Endpoints
- Bastion Host
- Cluster Autoscaler IAM role
- EKS Cluster

## Node Groups

- EKS Managed Node Groups
- Support for Graviton instances
- On-Demand Node Groups

## Add-ons

- vpc-cni
- coredns
- kube-proxy
- amazon-cloudwatch-observability

## Security

- IAM least privilege policies
- Security Groups
- IAM Roles for Kubernetes workloads
- Kubernetes RBAC integration

## Observability

- Control plane logs
- Container Insights support

## Prerequisites

| Tool         | Version           |
| ------------ | ----------------- |
| Terraform    | >= 1.5.7, < 2.0.0 |
| AWS Provider | >=6.0.0, < 7.0.0  |

## Repository Structure

```bash
.
├── eks.tf
├── network.tf
├── bastion_host.tf
├── cluster_autoscaler_irsa.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

## Quick Start
1. Clone Repository

```bash
git clone https://github.com/crifeboss/eks-module.git
```

2. Configure Variables
In another repository, pass the variables and reference the cloned module

Example:
```terraform
module "eks-lab" {
  source = "../eks-module"

  cluster_name          = "eks-lab"
  eks_version           = "1.34"
  availability_zones   = ["us-east-2a","us-east-2b","us-east-2c"]
  region                = "us-east-2"
  vpc_cidr                = "192.168.1.0/24"
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

| Variable              | Description         | Default   |
| --------------------- | ------------------- | ----------|
| cluster_name          | EKS cluster name    | n/a       |
| eks_version           | Kubernetes version  | n/a       |
| availability_zones    | Availability Zones  | n/a       |
| region                | Region              | n/a       |
| vpc_cidr              | VPC CIDR            | n/a       |
| public_subnet_cidr    | Public Subnet CIDR  | n/a       |
| private_subnet_cidrs  | Private Subnet CIDR | n/a       |

## Outputs

| Output                     | Description                 |
| -------------------------- | --------------------------- |
| cluster_autoscaler_rolearn | Cluster Autoscaler Role ARN |

Accessing the Cluster

```bash
aws eks update-kubeconfig --region <region name> --name <eks cluster name>
```

Verify:

```bash
kubectl get nodes
```

## Cluster Autoscaler Deploy

values.yaml
```yaml
rbac:
    serviceAccount:
        annotations:
            eks.amazonaws.com/role-arn: "<paste the output cluster autoscaler role arn>"
        name: cluster-autoscaler
awsRegion: <region name>
autoDiscovery:
    clusterName: <eks cluster name>
```

```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler -f values.yaml -n kube-system
kubectl get deployment -n kube-system cluster-autoscaler
```

## To verify cluster autoscaler is working
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-stress
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cpu-stress
  template:
    metadata:
      labels:
        app: cpu-stress
    spec:
      containers:
      - name: stress
        image: public.ecr.aws/eks-distro/kubernetes/pause:3.10
        resources:
          requests:
            cpu: "1000m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "512Mi"
```

- Check node has scaled up
```bash
kubectl get nodes
```

## To enable remote terraform backend

- Create S3 bucket initially
```terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket = "eks-lab-crife-tf-state"
  region = "us-east-2"
  force_destroy = false
}
```

- Enable the backend configuration
```terraform
terraform {
  backend "s3" {
    bucket         = "eks-lab-tf-state-01"
    key            = "lab/eks/terraform.tfstate"
    region         = "us-east-2"
    use_lockfile   = true
    encrypt        = true
  }
}
```

## Best Practices
Use private subnets for worker nodes and bastion host
Prefer Graviton instances for cost optimization
Store Terraform state in S3 with DynamoDB locking
Pin Terraform module versions
Enable CloudWatch logging
