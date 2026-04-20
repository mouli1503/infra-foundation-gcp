# Staging CI/CD IAM + GitHub OIDC + Remote State

This environment config provisions least-privilege IAM for staging CI/CD in GCP and supports GitHub OIDC federation using an existing Workload Identity Pool/Provider.

## 1) Configure remote Terraform state in GCS

Create a GCS bucket first (once), then initialize backend:

```bash
cd environments/supertails-internal
terraform init -reconfigure -backend-config=backend.hcl
```

If migrating existing local state:

```bash
terraform init -reconfigure -migrate-state -backend-config=backend.hcl
```

Example `backend.hcl`:

```hcl
bucket = "replace-with-terraform-state-bucket"
prefix = "supertails-internal"
```

## 2) Required tfvars

Use `terraform.staging-cicd.tfvars.example` as a template.

Required inputs for OIDC binding:
- `project_id`
- `project_number` (optional; auto-derived if omitted)
- `workload_identity_pool_id`
- `workload_identity_provider_id`
- `github_repository`

## 3) Plan and apply

```bash
cd environments/supertails-internal
terraform plan -var-file=terraform.tfvars -var-file=terraform.staging-cicd.tfvars
terraform apply -var-file=terraform.tfvars -var-file=terraform.staging-cicd.tfvars
```

## 4) GitHub secrets and repo variable

Set these exactly:

- `GCP_WIF_PROVIDER` = output `gcp_wif_provider_full_name`
- `GCP_DEPLOY_SA` = output `deploy_sa_email`
- `GCP_JOBS_INVOKER_SA` = local-part only from `invoker_sa_email` (example: `gha-jobs-invoker`)
- Repo Variable `GCP_PROJECT_ID` = your GCP project id

## 5) What gets provisioned

Service Accounts:
- `gha-staging-deploy`
- `gha-jobs-invoker`

APIs:
- `run.googleapis.com`
- `cloudscheduler.googleapis.com`
- `iamcredentials.googleapis.com`

IAM:
- Deploy SA:
  - `roles/run.developer` on project
  - `roles/cloudscheduler.admin` on project
  - `roles/iam.serviceAccountUser` on `gha-jobs-invoker` SA only
  - `roles/iam.workloadIdentityUser` for GitHub principalSet (single repository)
- Invoker SA:
  - `roles/run.invoker` on each configured Cloud Run Job (resource-level bindings)

## 6) Verification commands

```bash
# Replace placeholders.
PROJECT_ID="<GCP_PROJECT_ID>"
REGION="asia-south1"
DEPLOY_SA="gha-staging-deploy@${PROJECT_ID}.iam.gserviceaccount.com"
INVOKER_SA="gha-jobs-invoker@${PROJECT_ID}.iam.gserviceaccount.com"

# Verify project-level roles for deploy SA.
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${DEPLOY_SA}" \
  --format="table(bindings.role)"

# Verify deploy SA has actAs on invoker SA only.
gcloud iam service-accounts get-iam-policy "$INVOKER_SA" \
  --format="json(bindings)"

# Verify Cloud Run Job invoker bindings.
for job in pma-v2-ingestion pma-v2-engine-cycle pma-v2-execute pma-v2-auto-revert pma-v2-outcome-tracker; do
  echo "--- $job"
  gcloud run jobs get-iam-policy "$job" --region "$REGION" --project "$PROJECT_ID" \
    --format="table(bindings.role,bindings.members)" \
    --filter="bindings.members:serviceAccount:${INVOKER_SA}"
done

# Trigger a scheduler job once to validate end-to-end invocation.
# Replace with your scheduler job name.
gcloud scheduler jobs run <SCHEDULER_JOB_NAME> --location "$REGION" --project "$PROJECT_ID"

# Check latest execution status.
gcloud scheduler jobs describe <SCHEDULER_JOB_NAME> --location "$REGION" --project "$PROJECT_ID" \
  --format="value(state,status)"
```
