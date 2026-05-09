# =============================================================================
# Module: Compute
# =============================================================================

# ── VM Instances ──────────────────────────────────────────────────────────────
resource "google_compute_instance" "vms" {
  for_each = var.vm_instances

  name         = "${each.key}-${var.environment}"
  project      = var.project_id
  zone         = var.zone
  machine_type = each.value.machine_type
  tags         = each.value.tags
  labels       = var.common_labels

  boot_disk {
    initialize_params {
      image = each.value.image
      size  = each.value.disk_size_gb
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
    # No access_config = no external IP (uses Cloud NAT)
  }

  scheduling {
    preemptible       = each.value.preemptible
    automatic_restart = each.value.preemptible ? false : true
  }

  metadata = merge(each.value.metadata, {
    enable-oslogin = "TRUE"
  })

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

# ── GKE Clusters ──────────────────────────────────────────────────────────────
resource "google_container_cluster" "clusters" {
  for_each = var.gke_clusters

  name     = "${each.key}-${var.environment}"
  project  = var.project_id
  location = var.region

  network    = var.network
  subnetwork = var.subnetwork

  # Remove default node pool; manage nodes via separate node_pool resource
  remove_default_node_pool = true
  initial_node_count       = 1

  min_master_version = each.value.kubernetes_version == "latest" ? null : each.value.kubernetes_version

  dynamic "private_cluster_config" {
    for_each = each.value.private_cluster ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = false
      master_ipv4_cidr_block  = "172.16.0.0/28"
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  addons_config {
    http_load_balancing { disabled = false }
    horizontal_pod_autoscaling { disabled = false }
    network_policy_config { disabled = false }
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  release_channel {
    channel = "REGULAR"
  }

  resource_labels = var.common_labels
}

resource "google_container_node_pool" "pools" {
  for_each = var.gke_clusters

  name     = "${each.key}-pool-${var.environment}"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.clusters[each.key].name

  initial_node_count = each.value.node_count

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = "pd-ssd"

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = var.common_labels
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ── Managed Instance Groups ───────────────────────────────────────────────────
resource "google_compute_instance_template" "templates" {
  for_each = var.instance_groups

  name_prefix  = "${each.key}-${var.environment}-"
  project      = var.project_id
  machine_type = each.value.machine_type
  tags         = each.value.tags
  labels       = var.common_labels

  disk {
    source_image = each.value.image
    disk_size_gb = 50
    disk_type    = "pd-ssd"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "migs" {
  for_each = var.instance_groups

  name    = "${each.key}-mig-${var.environment}"
  project = var.project_id
  zone    = var.zone

  base_instance_name = "${each.key}-${var.environment}"
  target_size        = each.value.target_size

  version {
    instance_template = google_compute_instance_template.templates[each.key].id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.mig_health[each.key].id
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "autoscalers" {
  for_each = var.instance_groups

  name    = "${each.key}-autoscaler-${var.environment}"
  project = var.project_id
  zone    = var.zone
  target  = google_compute_instance_group_manager.migs[each.key].id

  autoscaling_policy {
    min_replicas    = each.value.min_replicas
    max_replicas    = each.value.max_replicas
    cooldown_period = each.value.cooldown_period

    cpu_utilization {
      target = 0.7
    }
  }
}

resource "google_compute_health_check" "mig_health" {
  for_each = var.instance_groups

  name    = "${each.key}-health-${var.environment}"
  project = var.project_id

  http_health_check {
    port = 80
  }
}
