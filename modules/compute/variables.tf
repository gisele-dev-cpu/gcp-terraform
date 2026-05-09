variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }
variable "environment" { type = string }
variable "common_labels" { type = map(string) }
variable "network" { type = string }
variable "subnetwork" { type = string }
variable "vm_instances" {
  type = map(object({
    machine_type = optional(string, "e2-medium")
    image        = optional(string, "debian-cloud/debian-12")
    disk_size_gb = optional(number, 50)
    preemptible  = optional(bool, false)
    tags         = optional(list(string), [])
    metadata     = optional(map(string), {})
  }))
}
variable "gke_clusters" {
  type = map(object({
    node_count         = optional(number, 1)
    machine_type       = optional(string, "e2-medium")
    min_node_count     = optional(number, 1)
    max_node_count     = optional(number, 3)
    disk_size_gb       = optional(number, 100)
    private_cluster    = optional(bool, true)
    kubernetes_version = optional(string, "latest")
  }))
}
variable "instance_groups" {
  type = map(object({
    machine_type    = optional(string, "e2-medium")
    image           = optional(string, "debian-cloud/debian-12")
    target_size     = optional(number, 1)
    min_replicas    = optional(number, 1)
    max_replicas    = optional(number, 5)
    cooldown_period = optional(number, 60)
    tags            = optional(list(string), [])
  }))
}
