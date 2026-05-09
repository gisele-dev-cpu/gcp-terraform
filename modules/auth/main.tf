# =============================================================================
# Module: auth
# Sets up authentication for CI/CD pipelines to impersonate the Terraform SA.
#
# Supports two methods (can enable both):
#   1. Workload Identity Federation  — keyless, recommended for GitHub Actions,
#                                      GitLab CI, and other OIDC-capable systems
#   2. Service account key           — traditional JSON key, stored as a secret
# =============================================================================

# ── Workload Identity Federation ──────────────────────────────────────────────
resource "google_iam_workload_identity_pool" "pool" {
  count = var.enable_wif ? 1 : 0

  project                   = var.project_id
  workload_identity_pool_id = "cicd-pool-${var.environment}"
  display_name              = "CI/CD Pool ${var.environment}"
  description               = "Allows CI/CD systems to authenticate without keys"
}

# GitHub Actions provider
resource "google_iam_workload_identity_pool_provider" "github" {
  count = var.enable_wif && var.github_org != null ? 1 : 0

  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Only allow tokens from your specific org/repo(s)
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = var.github_repo != null ? (
    "assertion.repository == '${var.github_org}/${var.github_repo}'"
    ) : (
    "assertion.repository.startsWith('${var.github_org}/')"
  )
}

# GitLab CI provider
resource "google_iam_workload_identity_pool_provider" "gitlab" {
  count = var.enable_wif && var.gitlab_url != null ? 1 : 0

  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "gitlab-ci"
  display_name                       = "GitLab CI"

  oidc {
    issuer_uri        = var.gitlab_url
    allowed_audiences = ["${var.gitlab_url}"]
  }

  attribute_mapping = {
    "google.subject"         = "assertion.sub"
    "attribute.project_path" = "assertion.project_path"
    "attribute.ref"          = "assertion.ref"
    "attribute.ref_type"     = "assertion.ref_type"
  }
}

# Allow WIF-authenticated identities to impersonate the Terraform SA
resource "google_service_account_iam_member" "wif_github_impersonation" {
  count = var.enable_wif && var.github_org != null ? 1 : 0

  service_account_id = var.terraform_sa_name
  role               = "roles/iam.workloadIdentityUser"

  member = var.github_repo != null ? (
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool[0].name}/attribute.repository/${var.github_org}/${var.github_repo}"
    ) : (
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool[0].name}/attribute.repository_owner/${var.github_org}"
  )
}

resource "google_service_account_iam_member" "wif_gitlab_impersonation" {
  count = var.enable_wif && var.gitlab_url != null ? 1 : 0

  service_account_id = var.terraform_sa_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool[0].name}/*"
}

# ── Service Account Key (fallback) ────────────────────────────────────────────
resource "google_service_account_key" "terraform_key" {
  count = var.enable_sa_key ? 1 : 0

  service_account_id = var.terraform_sa_name
  key_algorithm      = "KEY_ALG_RSA_2048"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

# Store the key in Secret Manager (never write to disk or state output)
resource "google_secret_manager_secret" "terraform_key" {
  count = var.enable_sa_key ? 1 : 0

  project   = var.project_id
  secret_id = "terraform-sa-key-${var.environment}"

  replication {
    auto {}
  }

  labels = var.common_labels
}

resource "google_secret_manager_secret_version" "terraform_key" {
  count = var.enable_sa_key ? 1 : 0

  secret      = google_secret_manager_secret.terraform_key[0].id
  secret_data = google_service_account_key.terraform_key[0].private_key
}
