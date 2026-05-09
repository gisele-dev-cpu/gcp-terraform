# =============================================================================
# Root Variables
# =============================================================================

# ── Project ──────────────────────────────────────────────────────────────────
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Default GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

# ── Networking ────────────────────────────────────────────────────────────────
variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "main-vpc"
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR range"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pod_cidr" {
  description = "Secondary CIDR for GKE pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "svc_cidr" {
  description = "Secondary CIDR for GKE services"
  type        = string
  default     = "10.2.0.0/20"
}

variable "allowed_ssh_ranges" {
  description = "CIDR ranges allowed SSH access"
  type        = list(string)
  default     = []
}

variable "allowed_http_ranges" {
  description = "CIDR ranges allowed HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ── IAM ───────────────────────────────────────────────────────────────────────
variable "service_accounts" {
  description = "Map of service accounts to create"
  type = map(object({
    display_name = string
    description  = optional(string, "")
    roles        = list(string)
  }))
  default = {}
}

variable "custom_roles" {
  description = "Map of custom IAM roles to create"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
  }))
  default = {}
}

# ── Storage ───────────────────────────────────────────────────────────────────
variable "buckets" {
  description = "Map of GCS buckets to create"
  type = map(object({
    location      = optional(string, "US")
    storage_class = optional(string, "STANDARD")
    versioning    = optional(bool, false)
    lifecycle_rules = optional(list(object({
      action_type          = string
      age_days             = optional(number)
      storage_class_target = optional(string)
    })), [])
    cors = optional(list(object({
      origins         = list(string)
      methods         = list(string)
      response_headers = list(string)
      max_age_seconds = number
    })), [])
  }))
  default = {}
}

variable "databases" {
  description = "Map of Cloud SQL instances to create"
  type = map(object({
    database_version = string
    tier             = optional(string, "db-f1-micro")
    deletion_protection = optional(bool, true)
    backup_enabled   = optional(bool, true)
    databases        = optional(list(string), [])
  }))
  default = {}
}

# ── Compute ───────────────────────────────────────────────────────────────────
variable "vm_instances" {
  description = "Map of Compute Engine VM instances"
  type = map(object({
    machine_type = optional(string, "e2-medium")
    image        = optional(string, "debian-cloud/debian-12")
    disk_size_gb = optional(number, 50)
    preemptible  = optional(bool, false)
    tags         = optional(list(string), [])
    metadata     = optional(map(string), {})
  }))
  default = {}
}

variable "gke_clusters" {
  description = "Map of GKE clusters to create"
  type = map(object({
    node_count        = optional(number, 1)
    machine_type      = optional(string, "e2-medium")
    min_node_count    = optional(number, 1)
    max_node_count    = optional(number, 3)
    disk_size_gb      = optional(number, 100)
    private_cluster   = optional(bool, true)
    kubernetes_version = optional(string, "latest")
  }))
  default = {}
}

variable "instance_groups" {
  description = "Map of managed instance groups"
  type = map(object({
    machine_type  = optional(string, "e2-medium")
    image         = optional(string, "debian-cloud/debian-12")
    target_size   = optional(number, 1)
    min_replicas  = optional(number, 1)
    max_replicas  = optional(number, 5)
    cooldown_period = optional(number, 60)
    tags          = optional(list(string), [])
  }))
  default = {}
}

# ── Project creation ──────────────────────────────────────────────────────────
variable "project_name" {
  description = "Human-readable GCP project name"
  type        = string
}

variable "org_id" {
  description = "GCP Organization ID (digits only, e.g. 123456789012)"
  type        = string
}

variable "folder_id" {
  description = "Optional folder ID to place the project under (overrides org_id direct placement)"
  type        = string
  default     = null
}

variable "billing_account_id" {
  description = "Billing account to link to the project (format: XXXXXX-XXXXXX-XXXXXX)"
  type        = string
}

variable "extra_apis" {
  description = "Additional GCP APIs to enable beyond the defaults"
  type        = list(string)
  default     = []
}

# ── Auth / CI-CD ──────────────────────────────────────────────────────────────
variable "gcp_access_token" {
  description = "Short-lived GCP access token (used by Workload Identity Federation in CI/CD). Leave null for local ADC."
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_wif" {
  description = "Enable Workload Identity Federation for keyless CI/CD authentication"
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub org or username to allow WIF from (e.g. 'my-org'). Null = skip GitHub WIF."
  type        = string
  default     = null
}

variable "github_repo" {
  description = "Specific GitHub repo to restrict WIF to. Null = allow all repos in the org."
  type        = string
  default     = null
}

variable "gitlab_url" {
  description = "GitLab instance URL for WIF (e.g. 'https://gitlab.com'). Null = skip GitLab WIF."
  type        = string
  default     = null
}

variable "enable_sa_key" {
  description = "Create a SA JSON key stored in Secret Manager (fallback if WIF is unavailable)"
  type        = bool
  default     = false
}
