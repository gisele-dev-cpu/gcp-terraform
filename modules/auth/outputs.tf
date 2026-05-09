output "workload_identity_pool_name" {
  description = "Full name of the Workload Identity pool (use in GitHub Actions config)"
  value       = var.enable_wif ? google_iam_workload_identity_pool.pool[0].name : null
}

output "workload_identity_provider_github" {
  description = "Full provider resource name for GitHub Actions (use as 'workload_identity_provider' in google-github-actions/auth)"
  value       = var.enable_wif && var.github_org != null ? google_iam_workload_identity_pool_provider.github[0].name : null
}

output "workload_identity_provider_gitlab" {
  description = "Full provider resource name for GitLab CI"
  value       = var.enable_wif && var.gitlab_url != null ? google_iam_workload_identity_pool_provider.gitlab[0].name : null
}

output "sa_key_secret_name" {
  description = "Secret Manager secret name containing the SA JSON key (if enabled)"
  value       = var.enable_sa_key ? google_secret_manager_secret.terraform_key[0].name : null
}
