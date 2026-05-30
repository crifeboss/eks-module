# EKS Infrastructure Deployment

## Overview

This Terraform project deploys the foundational AWS infrastructure required to run a private Amazon EKS cluster.

The deployment focuses on:

- Secure networking
- Private Kubernetes control plane access
- Bastion-based administration using AWS Systems Manager (SSM)
- Infrastructure as Code using Terraform

Cluster Autoscaler is not deployed by this project and will be installed separately using Helm.

## Resources Deployed

### VPC
- Dedicated VPC (192.168.1.0/24)

### Subnets
- 1 Public Subnet
- 3 Private Subnets across 3 AZs

### Networking
- Internet Gateway
- Route Tables
- VPC Endpoints (EC2, ECR, STS, SSM, CloudWatch, S3, logs, monitoring)

### EKS Cluster
- Private endpoint enabled
- Public endpoint disabled
- Managed Node Group
- CoreDNS
- kube-proxy
- VPC CNI
- Amazon Cloudwatch Observability

### Node Group
- Graviton-based worker nodes
- t4g.medium (cost optimized)
- Min: 1, Desired: 1, Max: 1

### Bastion Host
- Public EC2 instance where cluster autoscaler helm chart can be deployed to EKS cluster
- SSM-only access
- No Ingress

### Security
- Least privilege IAM
- Private worker nodes
- Private EKS API endpoint
- Security group restrictions

### Monitoring
- CloudWatch control plane logging
- CloudWatch Container Insights

## Accessing EKS

Connect to the bastion using SSM:

Configure kubectl:

example:
aws eks update-kubeconfig --region us-east-2 --name eks-lab

Validate:

kubectl get nodes
kubectl get pods -A

## Post Deployment

1. Verify node readiness
2. Verify EKS add-ons
3. Install Cluster Autoscaler using Helm
4. Deploy workloads
