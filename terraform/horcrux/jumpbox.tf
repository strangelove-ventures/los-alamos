resource "google_compute_instance" "vm_instance" {
  project      = var.project_id
  name         = "gke-${var.cluster_name}-jumpbox"
  machine_type = "e2-small"
  zone         = var.horcrux_cluster_zones[0]

  tags = ["${var.cluster_name}-jumpbox"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 20
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.sentry_subnetwork.id
    access_config {
    }
  }
}
