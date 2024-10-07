module "training_cluster" {
  source                   = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                  = "~> 31.0"
  project_id               = var.project_id
  name                     = "${var.cluster_prefix}-cluster"
  regional                 = true
  region                   = var.region
  network                  = var.network
  subnetwork               = var.subnetwork
  ip_range_pods            = "k8s-pod-range"
  ip_range_services        = "k8s-service-range"
  create_service_account   = true
  enable_private_endpoint  = false
  enable_private_nodes     = true
  master_ipv4_cidr_block   = "172.16.0.0/28"
  network_policy           = true
  logging_enabled_components = ["SYSTEM_COMPONENTS","WORKLOADS"]
  monitoring_enabled_components = ["SYSTEM_COMPONENTS"]
  enable_cost_allocation   = true
  deletion_protection      = false
  initial_node_count       = 1
  stateful_ha              = true
  grant_registry_access    = true
  kubernetes_version       = "latest"
  release_channel          = "RAPID"

  cluster_resource_labels = {
    name      = "${var.cluster_prefix}-cluster"
    component = "${var.cluster_prefix}-training"
  }

  monitoring_enable_managed_prometheus = true
  gke_backup_agent_config = true
 
  node_pools          = var.node_pools
  node_pools_labels   = var.node_pools_labels
  node_pools_taints   = var.node_pools_taints
  gce_pd_csi_driver   = true
  gcs_fuse_csi_driver = true
}

data "google_project" "project" {
  project_id               = var.project_id
}