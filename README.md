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
- Single VPC

### Subnets
- 1 Public Subnet
- 3 Private Subnets across 3 AZs

### Networking
- Single Nat Gateway
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
- Private EC2 instance where cluster autoscaler helm chart can be deployed to EKS cluster
- SSM-only access
- No Ingress

### Security
- Least privilege IAM
- Private worker nodes
- Private EKS API endpoint
- Security group restrictions
- EKS Cluster only access from bastion host

### Monitoring
- CloudWatch control plane logging
- CloudWatch Container Insights

## Accessing EKS

Connect to the bastion using SSM:

Configure kubeconfig:

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

helm repo add autoscaler https://kubernetes.github.io/autoscaler

cat values.yaml
rbac:
    serviceAccount:
        annotations:
            eks.amazonaws.com/role-arn: "arn:aws:iam::713545428997:role/cluster-autoscaler-role-20260530171201678200000001"
        name: cluster-autoscaler
awsRegion: us-east-2
autoDiscovery:
    clusterName: eks-lab

helm install cluster-autoscaler autoscaler/cluster-autoscaler -f values.yaml -n kube-system



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