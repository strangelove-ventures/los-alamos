module "gke_horcrux_validator_network" {
  source = "github.com/strangelove-ventures/los-alamos//terraform/horcrux"

  project_id            = "sl-hub-val"
  cluster_name          = "hub"
  region                = "us-west1"
  horcrux_cluster_zones = ["us-west1-a", "us-west1-b", "us-west1-c"]
  sentry_cluster_zones  = ["us-west1-a", "us-west1-b", "us-west1-c"]
  num_signer_nodes      = 1 # per zone
  num_sentry_nodes      = 1 # per zone
  sentry_machine_type   = "n2d-standard-4"
}
