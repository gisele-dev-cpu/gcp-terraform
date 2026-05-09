# =============================================================================
# GCP Infrastructure - Root Module
# =============================================================================

locals {
  common_labels = {
    project     = var.project_id
    environment = var.environment
    managed_by  = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Project (create project, enable APIs, state bucket, Terraform SA)
# Run first with org-admin credentials, then re-init pointing at the new bucket.
# -----------------------------------------------------------------------------
module "project" {
  source = "./modules/project"

  project_id         = var.project_id
  project_name       = var.project_name
  org_id             = var.org_id
  folder_id          = var.folder_id
  billing_account_id = var.billing_account_id
  region             = var.region
  environment        = var.environment
  common_labels      = local.common_labels
  extra_apis         = var.extra_apis
}

# -----------------------------------------------------------------------------
# Auth (Workload Identity Federation + optional SA key fallback)
# Wires up CI/CD pipelines to impersonate the Terraform service account.
# -----------------------------------------------------------------------------
module "auth" {
  source = "./modules/auth"

  project_id        = var.project_id
  environment       = var.environment
  common_labels     = local.common_labels
  terraform_sa_name = module.project.terraform_sa_name

  enable_wif  = var.enable_wif
  github_org  = var.github_org
  github_repo = var.github_repo
  gitlab_url  = var.gitlab_url
  enable_sa_key = var.enable_sa_key

  depends_on = [module.project]
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  common_labels = local.common_labels

  vpc_name                     = var.vpc_name
  subnet_cidr                  = var.subnet_cidr
  pod_cidr                     = var.pod_cidr
  svc_cidr                     = var.svc_cidr
  enable_private_google_access = true
  allowed_ssh_ranges           = var.allowed_ssh_ranges
  allowed_http_ranges          = var.allowed_http_ranges

  depends_on = [module.project]
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  project_id    = var.project_id
  environment   = var.environment
  common_labels = local.common_labels

  service_accounts = var.service_accounts
  custom_roles     = var.custom_roles

  depends_on = [module.project]
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------
module "storage" {
  source = "./modules/storage"

  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  common_labels = local.common_labels

  buckets   = var.buckets
  databases = var.databases

  depends_on = [module.project]
}

# -----------------------------------------------------------------------------
# Compute
# -----------------------------------------------------------------------------
module "compute" {
  source = "./modules/compute"

  project_id    = var.project_id
  region        = var.region
  zone          = var.zone
  environment   = var.environment
  common_labels = local.common_labels

  network    = module.networking.vpc_self_link
  subnetwork = module.networking.subnet_self_link

  vm_instances    = var.vm_instances
  gke_clusters    = var.gke_clusters
  instance_groups = var.instance_groups

  depends_on = [module.networking, module.iam]
}
