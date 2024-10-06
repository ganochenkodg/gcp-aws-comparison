module "eks" {
  source         = "../modules/eks-cluster"
  region         = var.region
  cluster_prefix = var.cluster_prefix
  snapshot_id    = var.snapshot_id
}

module "bucket" {
  source         = "../modules/s3-bucket"
  region         = var.region
  cluster_prefix = var.cluster_prefix
}

output "connection_command" {
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_prefix}-cluster"
  description = "EKS connection command"
}

