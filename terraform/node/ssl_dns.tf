resource "google_compute_managed_ssl_certificate" "default" {
  name    = var.cluster_name
  project = var.project_id

  managed {
    domains = [var.fqdn]
  }
}

resource "google_dns_record_set" "set" {
  name         = var.fqdn
  project      = var.project_id
  type         = "A"
  ttl          = 3600
  managed_zone = var.dns_managed_zone
  rrdatas      = [resource.google_compute_forwarding_rule.default.ip_address]
}