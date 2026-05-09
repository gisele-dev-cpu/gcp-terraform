# =============================================================================
# environments/dev/terraform.tfvars
# =============================================================================

# ── Project ───────────────────────────────────────────────────────────────────
project_id         = "gisele-platform-dev"
project_name       = "security-dev"
org_id             = "395135208830"          # gcloud organizations list
#folder_id          = null                    # or "folders/987654321" to nest under a folder
billing_account_id = "01FB47-2E2153-977634" # gcloud billing accounts list
region             = "us-central1"
zone               = "us-central1-a"
environment        = "dev"

extra_apis = [] # add any project-specific APIs here

# ── Auth / CI-CD ──────────────────────────────────────────────────────────────
enable_wif  = true
github_org  = "gisele-dev-cpu"   # your GitHub org or username
github_repo = "gcp-terraform"           # restrict to a specific repo, or set null for all repos
gitlab_url  = null              # set to "https://gitlab.com" if using GitLab CI
enable_sa_key = false           # set true only if WIF is not available

/*
# ── Networking ────────────────────────────────────────────────────────────────
vpc_name            = "main-vpc"
subnet_cidr         = "10.0.0.0/20"
pod_cidr            = "10.1.0.0/16"
svc_cidr            = "10.2.0.0/20"
allowed_ssh_ranges  = ["10.0.0.0/8"]
allowed_http_ranges = ["0.0.0.0/0"]

# ── IAM ───────────────────────────────────────────────────────────────────────
service_accounts = {
  "app-backend" = {
    display_name = "Backend Application SA"
    description  = "Used by backend application pods"
    roles = [
      "roles/cloudsql.client",
      "roles/storage.objectViewer",
      "roles/secretmanager.secretAccessor",
    ]
  }
}

custom_roles = {}

# ── Storage ───────────────────────────────────────────────────────────────────
buckets = {
  "assets" = {
    location   = "US"
    versioning = true
    lifecycle_rules = [{
      action_type          = "SetStorageClass"
      age_days             = 30
      storage_class_target = "NEARLINE"
    }]
  }
}

databases = {
  "app-db" = {
    database_version    = "POSTGRES_15"
    tier                = "db-f1-micro"
    deletion_protection = false
    backup_enabled      = true
    databases           = ["app"]
  }
}

# ── Compute ───────────────────────────────────────────────────────────────────
vm_instances = {}

gke_clusters = {
  "main" = {
    node_count      = 1
    machine_type    = "e2-standard-2"
    min_node_count  = 1
    max_node_count  = 3
    private_cluster = true
  }
}

instance_groups = {}
*/