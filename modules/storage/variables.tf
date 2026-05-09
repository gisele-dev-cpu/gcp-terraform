variable "project_id" { type = string }
variable "region" { type = string }
variable "environment" { type = string }
variable "common_labels" { type = map(string) }
variable "buckets" {
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
      origins          = list(string)
      methods          = list(string)
      response_headers = list(string)
      max_age_seconds  = number
    })), [])
  }))
}
variable "databases" {
  type = map(object({
    database_version    = string
    tier                = optional(string, "db-f1-micro")
    deletion_protection = optional(bool, true)
    backup_enabled      = optional(bool, true)
    databases           = optional(list(string), [])
  }))
}
