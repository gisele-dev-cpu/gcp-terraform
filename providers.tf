terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }

  backend "gcs" {
  }
}

provider "google" {
  project      = var.project_id
  region       = var.region
  access_token = var.gcp_access_token
}

provider "google-beta" {
  project      = var.project_id
  region       = var.region
  access_token = var.gcp_access_token
}
