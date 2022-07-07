module "gke_chain_node_network" {
  source = "github.com/strangelove-ventures/los-alamos//terraform/node"

  project_id       = "strangelove-infrastructure"
  cluster_name     = "cosmoshub"
  region           = "us-central1"
  cluster_zones    = ["us-central1-a", "us-central1-b"]
  dns_managed_zone = "strange-love"
  fqdn             = "cosmoshub.strange.love."
}
