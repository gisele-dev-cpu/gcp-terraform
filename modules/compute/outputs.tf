output "vm_instance_ips" {
  value = { for k, v in google_compute_instance.vms : k => v.network_interface[0].network_ip }
}

output "gke_cluster_endpoints" {
  value     = { for k, v in google_container_cluster.clusters : k => v.endpoint }
  sensitive = true
}

output "mig_instance_group_urls" {
  value = { for k, v in google_compute_instance_group_manager.migs : k => v.instance_group }
}
