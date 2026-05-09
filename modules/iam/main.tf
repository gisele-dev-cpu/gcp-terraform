# =============================================================================
# Module: IAM
# =============================================================================

# ── Service Accounts ──────────────────────────────────────────────────────────
resource "google_service_account" "accounts" {
  for_each = var.service_accounts

  project      = var.project_id
  account_id   = "${each.key}-${var.environment}"
  display_name = each.value.display_name
  description  = each.value.description
}

resource "google_project_iam_member" "sa_roles" {
  for_each = {
    for pair in flatten([
      for sa_key, sa in var.service_accounts : [
        for role in sa.roles : {
          key  = "${sa_key}/${role}"
          sa   = sa_key
          role = role
        }
      ]
    ]) : pair.key => pair
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.accounts[each.value.sa].email}"
}

# ── Custom Roles ──────────────────────────────────────────────────────────────
resource "google_project_iam_custom_role" "roles" {
  for_each = var.custom_roles

  project     = var.project_id
  role_id     = "${replace(each.key, "-", "_")}_${var.environment}"
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
}

# ── Workload Identity (for GKE) ───────────────────────────────────────────────
resource "google_service_account_iam_member" "workload_identity" {
  for_each = var.service_accounts

  service_account_id = google_service_account.accounts[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/${each.key}]"
}
