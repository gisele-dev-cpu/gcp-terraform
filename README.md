# GCP Terraform Infrastructure

Manages a full GCP project via Terraform — networking, IAM, storage, and compute — with per-environment configuration and a GCS remote backend.

## Project Structure

```
gcp-terraform/
├── main.tf                         # Root module wiring
├── variables.tf                    # All input variables
├── outputs.tf                      # Root outputs
├── providers.tf                    # Google provider + GCS backend
├── bootstrap.sh                    # One-time setup script
├── .gitignore
├── backends/
│   ├── dev.gcs.tfbackend
│   ├── staging.gcs.tfbackend
│   └── prod.gcs.tfbackend
├── environments/
│   ├── dev/terraform.tfvars
│   ├── staging/terraform.tfvars    # (create from dev as template)
│   └── prod/terraform.tfvars
└── modules/
    ├── networking/                 # VPC, subnets, Cloud NAT, firewall
    ├── iam/                        # Service accounts, custom roles
    ├── storage/                    # GCS buckets, Cloud SQL
    └── compute/                    # VMs, GKE clusters, MIGs
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) authenticated
- Owner or Editor on the target GCP project

## Quick Start

### 1. Bootstrap (run once per environment)

```bash
chmod +x bootstrap.sh
./bootstrap.sh YOUR_PROJECT_ID dev
```

This enables required GCP APIs and creates the GCS state bucket.

### 2. Configure your environment

Edit `environments/dev/terraform.tfvars` and replace `YOUR_PROJECT_ID` with your actual project ID. Adjust resources as needed.

### 3. Init, Plan, Apply

```bash
# Init with the correct backend
terraform init -backend-config=backends/dev.gcs.tfbackend

# Preview changes
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply
terraform apply -var-file=environments/dev/terraform.tfvars
```

### 4. Switching environments

```bash
# Re-init with different backend (Terraform will ask to migrate state)
terraform init -reconfigure -backend-config=backends/prod.gcs.tfbackend
terraform plan -var-file=environments/prod/terraform.tfvars
```

## What Gets Created

| Module | Resources |
|--------|-----------|
| **Networking** | VPC, regional subnet (with pod/svc secondary ranges), Cloud Router, Cloud NAT, firewall rules |
| **IAM** | Service accounts, project IAM bindings, custom roles, Workload Identity bindings |
| **Storage** | GCS buckets (versioned, uniform access, public-access blocked), Cloud SQL instances & databases |
| **Compute** | Compute Engine VMs (Shielded), GKE private clusters (Workload Identity, NetworkPolicy), Managed Instance Groups with autoscaling |

## Security Defaults

- All VMs have no external IPs; outbound internet via Cloud NAT
- GCS buckets enforce uniform bucket-level access and block public access
- GKE clusters are private with Workload Identity and network policy (Calico)
- Shielded instances enabled on all VMs and GKE nodes
- Firewall default-deny on ingress; explicit allowlists only
- OS Login enabled on VMs

## Adding Resources

All resources are driven by `tfvars` maps — no module code changes needed for common cases.

**Add a new GCS bucket:**
```hcl
buckets = {
  "my-new-bucket" = {
    versioning = true
  }
}
```

**Add a VM:**
```hcl
vm_instances = {
  "bastion" = {
    machine_type = "e2-small"
    tags         = ["ssh-allowed"]
  }
}
```

**Add a GKE cluster:**
```hcl
gke_clusters = {
  "workers" = {
    machine_type   = "e2-standard-4"
    max_node_count = 10
  }
}
```
