# -----------------------------------------------------------------------------
# Workload Identity Federation for GitHub Actions CI/CD
# Allows GitHub Actions to authenticate to GCP without service account keys.
# -----------------------------------------------------------------------------

data "google_project" "project" {
  project_id = var.project_id
}

locals {
  github_workload_identity_conditions = [
    for repo in var.github_workload_identity_repos :
    endswith(repo, "/*")
    ? "assertion.repository_owner == '${trimsuffix(repo, "/*")}'"
    : "assertion.repository == '${repo}'"
  ]
}

# Enable IAM Credentials API (required for Workload Identity Federation)
resource "google_project_service" "iam_credentials" {
  count              = var.enable_github_workload_identity ? 1 : 0
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_iam_workload_identity_pool" "github" {
  count                     = var.enable_github_workload_identity ? 1 : 0
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "Workload Identity Pool for GitHub Actions OIDC"
  project                   = var.project_id

  depends_on = [google_project_service.iam_credentials]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count                              = var.enable_github_workload_identity ? 1 : 0
  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"
  description                        = "OIDC provider for GitHub Actions"
  project                            = var.project_id

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.aud"              = "assertion.aud"
  }

  attribute_condition = local.github_workload_identity_conditions != [] ? join(" || ", local.github_workload_identity_conditions) : null

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service account for GitHub Actions to impersonate
resource "google_service_account" "github_actions" {
  count        = var.enable_github_workload_identity ? 1 : 0
  account_id   = "github-actions"
  display_name = "GitHub Actions CI/CD"
  project      = var.project_id
}

# Allow GitHub repos to impersonate the service account
resource "google_service_account_iam_member" "github_workload_identity" {
  for_each           = var.enable_github_workload_identity ? toset(var.github_workload_identity_repos) : toset([])
  service_account_id = google_service_account.github_actions[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github[0].workload_identity_pool_id}/attribute.repository/${split("/", each.value)[0]}/${split("/", each.value)[1]}"
}

# Allow GitHub repos to mint service account access tokens (impersonation)
resource "google_service_account_iam_member" "github_workload_identity_token_creator" {
  for_each           = var.enable_github_workload_identity ? toset(var.github_workload_identity_repos) : toset([])
  service_account_id = google_service_account.github_actions[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github[0].workload_identity_pool_id}/attribute.repository/${split("/", each.value)[0]}/${split("/", each.value)[1]}"
}

# Grant GitHub Actions SA permissions for CI/CD
resource "google_project_iam_member" "github_actions_artifact_registry" {
  count   = var.enable_github_workload_identity ? 1 : 0
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions[0].email}"
}

resource "google_project_iam_member" "github_actions_cloud_run" {
  count   = var.enable_github_workload_identity ? 1 : 0
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.github_actions[0].email}"
}

# Allow deployer SA to actAs the Cloud Run runtime service account.
# If `gcloud run deploy` doesn't specify `--service-account`, it uses the project's
# default Compute Engine service account: ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
resource "google_service_account_iam_member" "github_actions_act_as_compute_default" {
  count              = var.enable_github_workload_identity ? 1 : 0
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions[0].email}"
}

# Outputs for GitHub Actions workflow
output "workload_identity_provider" {
  description = "Workload Identity Provider resource name for use in GitHub Actions"
  value       = var.enable_github_workload_identity ? "projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github[0].workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.github[0].workload_identity_pool_provider_id}" : null
}

output "github_actions_service_account" {
  description = "Service account email for GitHub Actions (use with workload_identity_provider)"
  value       = var.enable_github_workload_identity ? google_service_account.github_actions[0].email : null
}
