variable "project_id" {
  description = "Globally unique GCP project ID (e.g. my-company-platform-dev)"
  type        = string
}

variable "project_name" {
  description = "Human-readable project name"
  type        = string
}

variable "org_id" {
  description = "GCP Organization ID (digits only, e.g. 123456789012)"
  type        = string
}

variable "folder_id" {
  description = "Optional folder ID to place the project under (overrides org_id placement)"
  type        = string
  default     = null
}

variable "billing_account_id" {
  description = "Billing account ID to link (format: XXXXXX-XXXXXX-XXXXXX)"
  type        = string
}

variable "region" {
  description = "Region for the state bucket"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "common_labels" {
  description = "Labels applied to all resources"
  type        = map(string)
}

variable "extra_apis" {
  description = "Additional GCP APIs to enable beyond the defaults"
  type        = list(string)
  default     = []
}
