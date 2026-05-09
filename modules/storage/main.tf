# =============================================================================
# Module: Storage
# =============================================================================

# ── GCS Buckets ───────────────────────────────────────────────────────────────
resource "google_storage_bucket" "buckets" {
  for_each = var.buckets

  name          = "${var.project_id}-${each.key}-${var.environment}"
  project       = var.project_id
  location      = each.value.location
  storage_class = each.value.storage_class
  labels        = var.common_labels

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = each.value.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action_type
        storage_class = lookup(lifecycle_rule.value, "storage_class_target", null)
      }
      condition {
        age = lookup(lifecycle_rule.value, "age_days", null)
      }
    }
  }

  dynamic "cors" {
    for_each = each.value.cors
    content {
      origin          = cors.value.origins
      method          = cors.value.methods
      response_header = cors.value.response_headers
      max_age_seconds = cors.value.max_age_seconds
    }
  }
}

# ── Cloud SQL ─────────────────────────────────────────────────────────────────
resource "google_sql_database_instance" "instances" {
  for_each = var.databases

  name             = "${each.key}-${var.environment}"
  project          = var.project_id
  region           = var.region
  database_version = each.value.database_version

  deletion_protection = each.value.deletion_protection

  settings {
    tier = each.value.tier

    backup_configuration {
      enabled            = each.value.backup_enabled
      binary_log_enabled = startswith(each.value.database_version, "MYSQL") ? each.value.backup_enabled : false
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${var.project_id}/global/networks/main-vpc-${var.environment}"
    }

    insights_config {
      query_insights_enabled = true
    }

    user_labels = var.common_labels
  }
}

resource "google_sql_database" "databases" {
  for_each = {
    for pair in flatten([
      for inst_key, inst in var.databases : [
        for db in inst.databases : {
          key      = "${inst_key}/${db}"
          instance = inst_key
          name     = db
        }
      ]
    ]) : pair.key => pair
  }

  project  = var.project_id
  instance = google_sql_database_instance.instances[each.value.instance].name
  name     = each.value.name
}
