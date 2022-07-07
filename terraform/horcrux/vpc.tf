resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "vpc-${var.cluster_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "sentry_subnetwork" {
  project       = var.project_id
  name          = "subnetwork-sentry-${var.cluster_name}"
  ip_cidr_range = var.sentry_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  secondary_ip_range {
    range_name    = "sentry-pods-${var.cluster_name}"
    ip_cidr_range = var.sentry_subnet_pods_cidr
  }
  secondary_ip_range {
    range_name    = "sentry-services-${var.cluster_name}"
    ip_cidr_range = var.sentry_subnet_service_cidr
  }
}

resource "google_compute_subnetwork" "horcrux_subnetwork" {
  project       = var.project_id
  name          = "subnetwork-horcrux-${var.cluster_name}"
  ip_cidr_range = var.horcrux_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  secondary_ip_range {
    range_name    = "horcrux-pods-${var.cluster_name}"
    ip_cidr_range = var.horcrux_subnet_pods_cidr
  }
  secondary_ip_range {
    range_name    = "horcrux-services-${var.cluster_name}"
    ip_cidr_range = var.horcrux_subnet_service_cidr
  }
}

resource "google_compute_router" "horcrux_nat_router" {
  depends_on = [resource.google_compute_subnetwork.horcrux_subnetwork]
  project    = var.project_id
  region     = var.region
  name       = "gke-${var.cluster_name}-horcrux-cloud-router"
  network    = google_compute_network.vpc_network.name
}

module "cloud-nat" {
  source  = "terraform-google-modules/cloud-nat/google"
  version = "~> 1.2"

  name                               = "gke-${var.cluster_name}-horcrux-nat-gateway"
  project_id                         = var.project_id
  region                             = var.region
  router                             = google_compute_router.horcrux_nat_router.name
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetworks = [
    {
      name                     = "subnetwork-horcrux-${var.cluster_name}"
      source_ip_ranges_to_nat  = [var.horcrux_subnet_cidr]
      secondary_ip_range_names = ["horcrux-services-${var.cluster_name}"]
    },
  ]
}
