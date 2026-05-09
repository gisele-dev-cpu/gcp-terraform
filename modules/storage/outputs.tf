output "bucket_urls" {
  value = { for k, v in google_storage_bucket.buckets : k => v.url }
}

output "database_connection_names" {
  value     = { for k, v in google_sql_database_instance.instances : k => v.connection_name }
  sensitive = true
}
