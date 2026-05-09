# =============================================================================
# Module: Networking
# =============================================================================

resource "google_compute_network" "vpc" {
  name                    = "${var.vpc_name}-${var.environment}"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.vpc_name}-subnet-${var.environment}"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.subnet_cidr

  private_ip_google_access = var.enable_private_google_access

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pod_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.svc_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ── Cloud Router & NAT (for private instances to reach internet) ──────────────
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router-${var.environment}"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat-${var.environment}"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ── Firewall Rules ─────────────────────────────────────────────────────────────
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal-${var.environment}"
  project = var.project_id
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr, var.pod_cidr, var.svc_cidr]
  description   = "Allow all internal traffic within VPC"
}

resource "google_compute_firewall" "allow_ssh" {
  count   = length(var.allowed_ssh_ranges) > 0 ? 1 : 0
  name    = "${var.vpc_name}-allow-ssh-${var.environment}"
  project = var.project_id
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_ranges
  target_tags   = ["ssh-allowed"]
  description   = "Allow SSH from specified ranges"
}

resource "google_compute_firewall" "allow_http" {
  count   = length(var.allowed_http_ranges) > 0 ? 1 : 0
  name    = "${var.vpc_name}-allow-http-${var.environment}"
  project = var.project_id
  network = google_compute_network.vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = var.allowed_http_ranges
  target_tags   = ["http-server", "https-server"]
  description   = "Allow HTTP/HTTPS from specified ranges"
}

resource "google_compute_firewall" "deny_all_ingress" {
  name     = "${var.vpc_name}-deny-all-ingress-${var.environment}"
  project  = var.project_id
  network  = google_compute_network.vpc.self_link
  priority = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Deny all other ingress traffic (lowest priority)"
}
