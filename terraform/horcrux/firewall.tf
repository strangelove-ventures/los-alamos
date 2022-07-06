# tendermint privval socket. Remove after moving to grpc
resource "google_compute_firewall" "sentry-privval" {
  project = var.project_id
  name    = "${var.cluster_name}-sentry-privval-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["31234"]
  }

  target_tags   = ["${var.cluster_name}-sentry-node"]
  source_ranges = [var.horcrux_subnet_cidr, var.horcrux_subnet_pods_cidr]
}

resource "google_compute_firewall" "sentry-p2p" {
  project = var.project_id
  name    = "${var.cluster_name}-sentry-p2p-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["26656"]
  }

  target_tags   = ["${var.cluster_name}-sentry-node"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "jumpbox" {
  project = var.project_id
  name    = "${var.cluster_name}-sentry-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["${var.cluster_name}-jumpbox"]
  source_ranges = ["0.0.0.0/0"]
}
