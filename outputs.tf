# =============================================================================
# Root Outputs
# =============================================================================

output "vpc_name" {
  description = "Name of the VPC network"
  value       = module.networking.vpc_name
}

output "vpc_self_link" {
  description = "Self-link of the VPC network"
  value       = module.networking.vpc_self_link
}

output "subnet_self_link" {
  description = "Self-link of the primary subnet"
  value       = module.networking.subnet_self_link
}

output "service_account_emails" {
  description = "Map of service account emails"
  value       = module.iam.service_account_emails
}

output "bucket_urls" {
  description = "Map of GCS bucket URLs"
  value       = module.storage.bucket_urls
}

output "database_connection_names" {
  description = "Map of Cloud SQL connection names"
  value       = module.storage.database_connection_names
  sensitive   = true
}

output "vm_instance_ips" {
  description = "Map of VM instance internal IPs"
  value       = module.compute.vm_instance_ips
}

output "gke_cluster_endpoints" {
  description = "Map of GKE cluster endpoints"
  value       = module.compute.gke_cluster_endpoints
  sensitive   = true
}

output "project_number" {
  description = "The GCP project number"
  value       = module.project.project_number
}

output "terraform_sa_email" {
  description = "Email of the Terraform CI/CD service account"
  value       = module.project.terraform_sa_email
}

output "wif_provider_github" {
  description = "Workload Identity provider name for GitHub Actions (use as 'workload_identity_provider')"
  value       = module.auth.workload_identity_provider_github
}

output "wif_provider_gitlab" {
  description = "Workload Identity provider name for GitLab CI"
  value       = module.auth.workload_identity_provider_gitlab
}

output "sa_key_secret_name" {
  description = "Secret Manager secret holding the SA JSON key (if SA key auth is enabled)"
  value       = module.auth.sa_key_secret_name
}
