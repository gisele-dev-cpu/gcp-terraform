output "service_account_emails" {
  value = { for k, v in google_service_account.accounts : k => v.email }
}

output "custom_role_ids" {
  value = { for k, v in google_project_iam_custom_role.roles : k => v.id }
}
