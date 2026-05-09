#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh
#
# Phase 1: Authenticate with org-admin credentials and apply only the project
#          module. This creates the GCP project, enables APIs, creates the
#          state bucket and Terraform service account.
#
# Phase 2: Re-init Terraform pointing at the new state bucket, then apply the
#          auth module (WIF / SA key). After that, CI/CD can take over.
#
# Usage: ./bootstrap.sh <environment> [--skip-project]
#   --skip-project   Skip Phase 1 (project already exists)
# =============================================================================
set -euo pipefail

ENVIRONMENT="${1:?Usage: $0 <environment> [--skip-project]}"
SKIP_PROJECT="${2:-}"

TFVARS="environments/${ENVIRONMENT}/terraform.tfvars"

if [[ ! -f "$TFVARS" ]]; then
  echo "Missing: ${TFVARS}"
  echo "Copy environments/dev/terraform.tfvars and fill in your values."
  exit 1
fi

# Extract a value from tfvars
tfvar() {
  grep -E "^${1}\s*=" "$TFVARS" | sed 's/.*=\s*"\(.*\)"/\1/' | tr -d ' '
}

PROJECT_ID=$(tfvar project_id)
BUCKET="${PROJECT_ID}-tfstate-${ENVIRONMENT}"

echo ""
echo "======================================================"
echo "  GCP Terraform Bootstrap  |  env: ${ENVIRONMENT}"
echo "  Project: ${PROJECT_ID}"
echo "======================================================"
echo ""

# Phase 1: Create the project
if [[ "$SKIP_PROJECT" != "--skip-project" ]]; then
  echo "Phase 1: Authenticating as org admin..."
  echo "You need Organization Admin + Billing Account User roles."
  echo "Run: gcloud auth login && gcloud auth application-default login"
  echo ""
  read -r -p "Press ENTER when authenticated, or Ctrl-C to abort..."
  echo ""

  echo "Initialising Terraform with local backend for project bootstrapping..."
  terraform init -backend=false

  echo "Applying project module only..."
  terraform apply \
    -var-file="$TFVARS" \
    -target=module.project \
    -auto-approve

  echo ""
  echo "Project created. State bucket: gs://${BUCKET}"
  echo ""

  echo "Updating backend config..."
  sed -i.bak "s/YOUR_PROJECT_ID/${PROJECT_ID}/g" "backends/${ENVIRONMENT}.gcs.tfbackend"
  rm -f "backends/${ENVIRONMENT}.gcs.tfbackend.bak"
fi

# Phase 2: Migrate state to GCS, apply auth
echo "Phase 2: Re-initialising with GCS backend..."
terraform init \
  -backend-config="backends/${ENVIRONMENT}.gcs.tfbackend" \
  -migrate-state \
  -force-copy

echo "Applying auth module (Workload Identity Federation / SA key)..."
terraform apply \
  -var-file="$TFVARS" \
  -target=module.auth \
  -auto-approve

echo ""
echo "Fetching CI/CD configuration values..."
TF_SA=$(terraform output -raw terraform_sa_email 2>/dev/null || echo "(not set)")
WIF_PROVIDER=$(terraform output -raw wif_provider_github 2>/dev/null || echo "(not set)")

echo ""
echo "======================================================"
echo "  Bootstrap complete!"
echo ""
echo "  Add these as GitHub Actions secrets:"
echo ""
echo "    GCP_TERRAFORM_SA_EMAIL = ${TF_SA}"
echo "    GCP_WIF_PROVIDER       = ${WIF_PROVIDER}"
echo ""
echo "  Then apply the full stack:"
echo "    terraform apply -var-file=${TFVARS}"
echo "======================================================"
echo ""
