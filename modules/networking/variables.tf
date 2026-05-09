variable "project_id" { 
    type = string 
    }
variable "region" { 
    type = string 
    }
variable "environment" { 
    type = string 
    }
variable "common_labels" {
     type = map(string) 
     }
variable "vpc_name" { 
    type = string 
    }
variable "subnet_cidr" {
     type = string
 }
variable "pod_cidr" {
     type = string 
     }
variable "svc_cidr" { 
    type = string 
    }
variable "enable_private_google_access" { 
    type = bool
 default = true 
 }
variable "allowed_ssh_ranges" { 
    type = list(string) 
    }
variable "allowed_http_ranges" { 
    type = list(string) 
    }
