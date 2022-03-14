provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  depends_on = [resource.google_compute_subnetwork.subnetwork]
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = var.project_id
  name                       = var.cluster_name
  region                     = var.region
  zones                      = var.cluster_zones
  network                    = "vpc-${var.cluster_name}"
  subnetwork                 = "subnetwork-${var.cluster_name}"
  ip_range_pods              = "pods-${var.cluster_name}"
  ip_range_services          = "services-${var.cluster_name}"
  http_load_balancing        = false
  horizontal_pod_autoscaling = false
  network_policy             = false
  enable_private_endpoint    = false
  enable_private_nodes       = false
  master_ipv4_cidr_block     = var.master_cidr
  remove_default_node_pool   = true

  node_pools = [
    {
      name                      = "chain-node-pool"
      node_count                = var.num_nodes
      disk_size_gb              = var.disk_size_gb
      machine_type              = var.machine_type
      disk_type                 = var.disk_type
      image_type                = var.image_type
      auto_repair               = true
      auto_upgrade              = true
      autoscaling               = false
      preemptible               = false
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    chain-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_tags = {
    chain-node-pool = [ "${var.cluster_name}-node" ]
  }
}
