module "network" {
  source         = "../modules/network"
  project_id     = var.project_id
  region         = var.region
  cluster_prefix = var.cluster_prefix
}

module "training_cluster" {
  source                   = "../modules/cluster"
  project_id               = var.project_id
  region                   = var.region
  cluster_prefix           = var.cluster_prefix
  network                  = module.network.network_name
  subnetwork               = module.network.subnet_name

  node_pools = [
    {
      name                = "model-train-pool"
      disk_size_gb        = var.node_disk_size
      disk_type           = "pd-balanced"
      node_locations      = var.node_location
      autoscaling         = true
      min_count           = 1
      max_count           = var.autoscaling_max_count
      max_surge           = 1
      max_unavailable     = 0
      machine_type        = "g2-standard-8"
      local_nvme_ssd_count     = 1
      auto_repair         = true
      accelerator_count   = 1
      accelerator_type    = "nvidia-l4"
      gpu_driver_version  = "LATEST"
    }
  ]
  
  node_pools_labels = {
    all = {}
    model-train-pool = {
      "app.stateful/component" = "model-train"
    }
  }
  node_pools_taints = {
    all = []
    model-train-pool = [
      {
        key    = "app.stateful/component"
        value  = "model-train"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}

output "kubectl_connection_command" {
  value       = "gcloud container clusters get-credentials ${var.cluster_prefix}-cluster --region ${var.region}"
  description = "Connection command"
}