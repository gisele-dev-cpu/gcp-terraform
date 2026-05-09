# =============================================================================
# environments/prod/terraform.tfvars
# =============================================================================

project_id  = "YOUR_PROJECT_ID"
region      = "us-central1"
zone        = "us-central1-a"
environment = "prod"

vpc_name            = "main-vpc"
subnet_cidr         = "10.10.0.0/20"
pod_cidr            = "10.11.0.0/16"
svc_cidr            = "10.12.0.0/20"
allowed_ssh_ranges  = []             # no direct SSH in prod; use IAP
allowed_http_ranges = ["0.0.0.0/0"]

service_accounts = {
  "app-backend" = {
    display_name = "Backend Application SA"
    roles = [
      "roles/cloudsql.client",
      "roles/storage.objectViewer",
      "roles/secretmanager.secretAccessor",
    ]
  }
  "ci-deployer" = {
    display_name = "CI/CD Deployer SA"
    roles = [
      "roles/container.developer",
      "roles/storage.admin",
    ]
  }
}

custom_roles = {}

buckets = {
  "assets" = {
    location      = "US"
    storage_class = "STANDARD"
    versioning    = true
    lifecycle_rules = [
      {
        action_type          = "SetStorageClass"
        age_days             = 90
        storage_class_target = "NEARLINE"
      }
    ]
  }
  "backups" = {
    location      = "US"
    storage_class = "NEARLINE"
    versioning    = true
  }
}

databases = {
  "app-db" = {
    database_version    = "POSTGRES_15"
    tier                = "db-custom-4-15360"  # 4 vCPU, 15GB RAM
    deletion_protection = true
    backup_enabled      = true
    databases           = ["app", "analytics"]
  }
}

vm_instances = {}

gke_clusters = {
  "main" = {
    node_count      = 3
    machine_type    = "e2-standard-4"
    min_node_count  = 3
    max_node_count  = 10
    private_cluster = true
  }
}

instance_groups = {}
