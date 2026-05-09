# =============================================================================
# Module: project
# Creates a GCP project under an organization, enables APIs, links billing.
# Must be applied with org-level credentials BEFORE other modules.
# =============================================================================

resource "google_project" "project" {
  name            = var.project_name
  project_id      = var.project_id
  org_id          = var.folder_id == null ? var.org_id : null
  folder_id       = var.folder_id != null ? var.folder_id : null
  billing_account = var.billing_account_id

  auto_create_network = false # we manage networking ourselves

  labels = var.common_labels

  lifecycle {
    prevent_destroy = true # safety: never accidentally delete the project
  }
}

# ── Wait for project to be ready ──────────────────────────────────────────────
resource "time_sleep" "wait_for_project" {
  depends_on      = [google_project.project]
  create_duration = "10s"
}

# ── Enable APIs ───────────────────────────────────────────────────────────────
resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)

  project                    = google_project.project.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false

  depends_on = [time_sleep.wait_for_project]
}

locals {
  required_apis = concat([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudkms.googleapis.com",
    "artifactregistry.googleapis.com",
    "dns.googleapis.com",
    "sts.googleapis.com", # required for Workload Identity Federation
  ], var.extra_apis)
}

# ── Terraform state bucket (created inside the new project) ──────────────────
resource "google_storage_bucket" "tf_state" {
  name          = "${var.project_id}-tfstate-${var.environment}"
  project       = google_project.project.project_id
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = false

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action { type = "Delete" }
    condition {
      num_newer_versions = 10 # keep last 10 state versions
    }
  }

  labels = var.common_labels

  depends_on = [google_project_service.apis]
}

# ── Terraform service account (used by CI/CD to manage infra) ─────────────────
resource "google_service_account" "terraform" {
  project      = google_project.project.project_id
  account_id   = "terraform-${var.environment}"
  display_name = "Terraform IaC Service Account (${var.environment})"
  description  = "Used by Terraform/CI-CD to manage project resources"

  depends_on = [google_project_service.apis]
}

# Grant the Terraform SA the roles it needs to manage all resources
resource "google_project_iam_member" "terraform_roles" {
  for_each = toset([
    "roles/editor",                          # broad resource management
    "roles/iam.securityAdmin",               # manage IAM policies
    "roles/resourcemanager.projectIamAdmin", # set project-level IAM
    "roles/storage.admin",                   # manage state bucket
    "roles/compute.networkAdmin",            # networking
    "roles/container.admin",                 # GKE
  ])

  project = google_project.project.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform.email}"

  depends_on = [google_project_service.apis]
}

# Allow the Terraform SA to access the state bucket
resource "google_storage_bucket_iam_member" "terraform_state_access" {
  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.terraform.email}"
}
