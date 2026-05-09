variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "common_labels" {
  description = "Labels applied to all resources"
  type        = map(string)
}

variable "terraform_sa_name" {
  description = "Full resource name of the Terraform service account (from project module output)"
  type        = string
}

# ── Workload Identity Federation ──────────────────────────────────────────────
variable "enable_wif" {
  description = "Enable Workload Identity Federation (keyless auth)"
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub organization or username (e.g. 'my-org'). Set to enable GitHub Actions WIF."
  type        = string
  default     = null
}

variable "github_repo" {
  description = "Specific GitHub repo to restrict WIF to (e.g. 'infra'). Null = allow all repos in the org."
  type        = string
  default     = null
}

variable "gitlab_url" {
  description = "GitLab instance URL (e.g. 'https://gitlab.com'). Set to enable GitLab CI WIF."
  type        = string
  default     = null
}

# ── Service Account Key ───────────────────────────────────────────────────────
variable "enable_sa_key" {
  description = "Create a JSON key and store in Secret Manager (use only if WIF is not available)"
  type        = bool
  default     = false
}
