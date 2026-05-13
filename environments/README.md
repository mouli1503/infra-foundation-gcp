# Environments (separate directories)

Each subdirectory is a self-contained Terraform config for a different GCP project.

| Directory | Project | Domain |
|-----------|---------|--------|
| `supertails-internal/` | `sup-internal-apps` (prod internal) | `apps.internal.supertails.com` |
| `supertails-internal-staging/` | `internal-apps-staging` (staging internal) | `apps.staging.supertails.com` |
| `supertails-vc/` | SuperTailsVC | `apps.product.supertails.com` |

## Deploy to SuperTails Internal Apps (prod)

```bash
cd environments/supertails-internal
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## Deploy to SuperTails Internal Apps (staging)

1. Create the GCS bucket for state (one-time):
   ```bash
   gcloud storage buckets create gs://internal-apps-staging-tfstate \
     --project=internal-apps-staging \
     --location=asia-south1 \
     --uniform-bucket-level-access
   gcloud storage buckets update gs://internal-apps-staging-tfstate --versioning
   ```
2. Fill in `terraform.tfvars` as you migrate services (`routes`, `iap_*`).
3. Apply:
   ```bash
   cd environments/supertails-internal-staging
   cp backend.hcl.example backend.hcl
   terraform init -backend-config=backend.hcl
   terraform plan
   terraform apply
   ```

## Deploy to SuperTailsVC

1. Edit `terraform.tfvars` with your project ID, domain, routes, and IAP config.
2. Create the GCP project and enable required APIs if needed.
3. Run:

```bash
cd environments/supertails-vc
cp backend.hcl.example backend.hcl
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## Notes

- Each environment has its own state bucket (no workspaces; complete isolation).
- Changes in one directory do not affect the others.
- Route keys must be lowercase with hyphens (e.g. `decision-engine` not `decisionEngine`).
- Staging uses the short domain `apps.staging.supertails.com`. Service URLs become `https://{route}.apps.staging.supertails.com/`.
