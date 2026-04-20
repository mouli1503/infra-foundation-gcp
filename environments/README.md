# Environments

Each subdirectory is a self-contained Terraform root for a different GCP project.

| Directory | Project |
|-----------|---------|
| `supertails-internal/` | SuperTails Internal Apps (`sup-internal-apps`) |
| `supertails-vc/` | SuperTailsVC |

## Shared Staging CI/CD Config

Both environments now use the shared module at `modules/staging-cicd-github-oidc` for:
- `gha-staging-deploy` service account
- `gha-jobs-invoker` service account
- GitHub OIDC binding to deploy SA (`roles/iam.workloadIdentityUser`)
- Deploy SA permissions (`roles/run.developer`, `roles/cloudscheduler.admin`, `roles/iam.serviceAccountUser` on invoker SA)
- Per-job `roles/run.invoker` for Cloud Run Jobs
- Existing Workload Identity Pool/Provider reuse (the module does not create WIF pool/provider resources)

## Remote State (GCS)

Each environment includes:
- `backend.tf`
- `backend.hcl.example`

Create `backend.hcl` per environment, then initialize:

```bash
cd environments/<env>
terraform init -reconfigure -backend-config=backend.hcl
# if migrating local state
terraform init -reconfigure -migrate-state -backend-config=backend.hcl
```

## Deploy (per environment)

```bash
cd environments/<env>
terraform plan -var-file=terraform.tfvars -var-file=terraform.staging-cicd.tfvars
terraform apply -var-file=terraform.tfvars -var-file=terraform.staging-cicd.tfvars
```

Use each environment's `terraform.staging-cicd.tfvars.example` as template.

## Staging CI/CD tfvars Example

`terraform.staging-cicd.tfvars`:

```hcl
project_id  = "<GCP_PROJECT_ID>"
region      = "asia-south1"

# Optional: if omitted, Terraform derives it from project_id.
project_number = "123456789012"

# Existing WIF pool/provider IDs only (not full resource names).
workload_identity_pool_id     = "github-actions"
workload_identity_provider_id = "github-oidc"

# Exact trusted repository (no wildcard).
github_repository = "SupertailsPCPL/performance-marketing-agent"

cloud_run_job_names = [
  "pma-v2-ingestion",
  "pma-v2-engine-cycle",
  "pma-v2-execute",
  "pma-v2-auto-revert",
  "pma-v2-outcome-tracker"
]
```

`supertails-vc` only: set `enable_github_workload_identity = false` in `terraform.staging-cicd.tfvars` when you are reusing an existing WIF pool/provider.

## GitHub Repo Secrets and Variables

Set these exactly after apply:
- `GCP_WIF_PROVIDER` = Terraform output `gcp_wif_provider_full_name`
- `GCP_DEPLOY_SA` = Terraform output `deploy_sa_email`
- `GCP_JOBS_INVOKER_SA` = local part of `invoker_sa_email` (example: `gha-jobs-invoker`)
- Repo variable `GCP_PROJECT_ID` = your GCP project id

## Short Apply Checklist

1. Confirm existing WIF pool/provider IDs (`workload_identity_pool_id`, `workload_identity_provider_id`) in the target project.
2. Copy `terraform.staging-cicd.tfvars.example` to `terraform.staging-cicd.tfvars` and set values.
3. Run `terraform init -reconfigure -backend-config=backend.hcl`.
4. Run `terraform plan -var-file=terraform.tfvars -var-file=terraform.staging-cicd.tfvars`.
5. Run `terraform apply -var-file=terraform.tfvars -var-file=terraform.staging-cicd.tfvars`.
6. Copy outputs into GitHub repository secrets/variables.

## Verification Commands

```bash
PROJECT_ID="<GCP_PROJECT_ID>"
REGION="asia-south1"
WIF_POOL_ID="github-actions"
DEPLOY_SA="gha-staging-deploy@${PROJECT_ID}.iam.gserviceaccount.com"
INVOKER_SA="gha-jobs-invoker@${PROJECT_ID}.iam.gserviceaccount.com"

# Required APIs.
gcloud services list --enabled --project "$PROJECT_ID" \
  --filter="name:run.googleapis.com OR name:cloudscheduler.googleapis.com OR name:iamcredentials.googleapis.com"

# Deploy SA project-level roles.
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${DEPLOY_SA}" \
  --format="table(bindings.role)"

# Deploy SA actAs on invoker SA.
gcloud iam service-accounts get-iam-policy "$INVOKER_SA" --project "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${DEPLOY_SA}" \
  --format="table(bindings.role)"

# Invoker SA run.invoker per Cloud Run Job.
for job in pma-v2-ingestion pma-v2-engine-cycle pma-v2-execute pma-v2-auto-revert pma-v2-outcome-tracker; do
  echo "---- $job"
  gcloud run jobs get-iam-policy "$job" --region "$REGION" --project "$PROJECT_ID" \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:${INVOKER_SA}" \
    --format="table(bindings.role)"
done

# WIF principal binding on deploy SA (single repository principalSet).
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')"
gcloud iam service-accounts get-iam-policy "$DEPLOY_SA" --project "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL_ID}/attribute.repository/SupertailsPCPL/performance-marketing-agent" \
  --format="table(bindings.role,bindings.members)"

# Run scheduler job manually and inspect latest status.
gcloud scheduler jobs run <SCHEDULER_JOB_NAME> --location "$REGION" --project "$PROJECT_ID"
gcloud scheduler jobs describe <SCHEDULER_JOB_NAME> --location "$REGION" --project "$PROJECT_ID" \
  --format="value(state,status)"
```
