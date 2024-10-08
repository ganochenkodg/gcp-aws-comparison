module "gcp-network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.1.0"

  project_id   = var.project_id
  network_name = "${var.cluster_prefix}-vpc"

  subnets = [
    {
      subnet_name           = "${var.cluster_prefix}-private-subnet"
      subnet_ip             = "10.10.0.0/24"
      subnet_region         = var.region
      subnet_private_access = true
      subnet_flow_logs      = "true"
    }
  ]

  secondary_ranges = {
    ("${var.cluster_prefix}-private-subnet") = [
      {
        range_name    = "k8s-pod-range"
        ip_cidr_range = "10.48.0.0/20"
      },
      {
        range_name    = "k8s-service-range"
        ip_cidr_range = "10.52.0.0/20"
      },
    ]
  }
}

module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version = "~> 8.0"
  project_id   = var.project_id
  network_name = module.gcp-network.network_name

  ingress_rules = [{
    name                    = "allow-ssh-for-cloudbuild"
    description             = "open webhook port"
    source_ranges           = ["35.235.240.0/20"]
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    deny = []
  }]
}

output "network_name" {
  value = module.gcp-network.network_name
}

output "subnet_name" {
  value = module.gcp-network.subnets_names[0]
}
# [END gke_model_train_vpc_multi_region_network]

# [START gke_model_train_cloudnat_simple_create]
module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.0"
  project = var.project_id 
  name    = "${var.cluster_prefix}-nat-router"
  network = module.gcp-network.network_name
  region  = var.region
  nats = [{
    name = "${var.cluster_prefix}-nat"
  }]
}