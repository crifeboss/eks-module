output "cluster_autoscaler_rolearn" {
    value = module.cluster_autoscaler_irsa.arn
    description = "Cluster Autoscaler Role arn"
}