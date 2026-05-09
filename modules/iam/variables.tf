variable "project_id" {
  type = string
}
variable "environment" {
  type = string
}
variable "common_labels" {
  type = map(string)
}
variable "service_accounts" {
  type = map(object({
    display_name = string
    description  = optional(string, "")
    roles        = list(string)
  }))
}
variable "custom_roles" {
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
  }))
}
