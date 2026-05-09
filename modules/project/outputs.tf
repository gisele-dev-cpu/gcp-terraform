output "project_id" {
  description = "The created project ID"
  value       = google_project.project.project_id
}

output "project_number" {
  description = "The created project number"
  value       = google_project.project.number
}

output "tf_state_bucket" {
  description = "Name of the Terraform state GCS bucket"
  value       = google_storage_bucket.tf_state.name
}

output "terraform_sa_email" {
  description = "Email of the Terraform service account"
  value       = google_service_account.terraform.email
}

output "terraform_sa_name" {
  description = "Full resource name of the Terraform service account"
  value       = google_service_account.terraform.name
}
