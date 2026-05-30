variable "vpc_cidr" {
    description = "VPC CIDR"
    type = string
}

variable "public_subnet_cidr" {
    description = "Public Subnet CIDR"
    type = list(string)
}

variable "private_subnet_cidrs" {
    description = "Private Subnet CIDR"
    type = list(string)
}

variable "availability_zones" {
    description = "Availability Zones"
    type = list(string)
}

variable "region" {
    description = "AWS Region"
    type = string
}

variable "eks_version" {
    description = "EKS Version"
    type = string
}

variable "cluster_name" {
    description = "EKS Cluster Name"
    type = string
}