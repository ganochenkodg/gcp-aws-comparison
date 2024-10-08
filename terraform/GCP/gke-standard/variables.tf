variable "project_id" {
  description = "The project ID to host the cluster in"
  default     = ""
}

variable "region" {
  description = "The region to host the cluster in"
}

variable "cluster_prefix" {
  description = "The prefix for all cluster resources"
  default     = "llm"
}

variable "node_location" {
  description = "Node location for GPU node pool - please check GPUs node availability in official documentation: https://cloud.google.com/compute/docs/regions-zones"
  type        = string
  default     = ""
  
}

variable "node_machine_type" {
  description = "The machine type for node instances"
  default     = "e2-standard-2"
  type        = string
}

variable "node_disk_type" {
  description = "The persistent disk type for node instances"
  default     = "pd-standard"
  type        = string
}
variable "node_disk_size" {
  description = "The persistent disk size for node instances"
  default     = 100
  type        = number
}

variable "autoscaling_max_count" {
  description = "Maximum node counts per zone"
  default     = 2
  type        = number
}