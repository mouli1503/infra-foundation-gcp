data "google_project" "project" {
  project_id = var.project_id
}

locals {
  effective_project_number = coalesce(var.project_number, tostring(data.google_project.project.number))

  github_repo_principal = var.enable ? format(
    "principalSet://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s/attribute.repository/%s",
    local.effective_project_number,
    var.workload_identity_pool_id,
    var.github_repository
  ) : null

  gcp_wif_provider_full_name = var.enable ? format(
    "projects/%s/locations/global/workloadIdentityPools/%s/providers/%s",
    local.effective_project_number,
    var.workload_identity_pool_id,
    var.workload_identity_provider_id
  ) : null
}

resource "google_service_account" "gha_staging_deploy" {
  count = var.enable ? 1 : 0

  project      = var.project_id
  account_id   = var.staging_deploy_sa_account_id
  display_name = "GitHub Actions Staging Deployer"
}

resource "google_service_account" "gha_jobs_invoker" {
  count = var.enable ? 1 : 0

  project      = var.project_id
  account_id   = var.jobs_invoker_sa_account_id
  display_name = "Cloud Scheduler OIDC Invoker"
}

resource "google_project_iam_member" "gha_staging_deploy_run_developer" {
  count = var.enable ? 1 : 0

  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.gha_staging_deploy[0].email}"
}

resource "google_project_iam_member" "gha_staging_deploy_cloudscheduler_admin" {
  count = var.enable ? 1 : 0

  project = var.project_id
  role    = "roles/cloudscheduler.admin"
  member  = "serviceAccount:${google_service_account.gha_staging_deploy[0].email}"
}

resource "google_service_account_iam_member" "gha_staging_deploy_service_account_user_on_invoker" {
  count = var.enable ? 1 : 0

  service_account_id = google_service_account.gha_jobs_invoker[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.gha_staging_deploy[0].email}"
}

resource "google_cloud_run_v2_job_iam_member" "jobs_invoker_run_invoker" {
  for_each = var.enable ? var.cloud_run_job_names : toset([])

  project  = var.project_id
  location = var.region
  name     = each.value

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.gha_jobs_invoker[0].email}"
}

resource "google_service_account_iam_member" "gha_staging_deploy_wif_user" {
  count = var.enable ? 1 : 0

  service_account_id = google_service_account.gha_staging_deploy[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.github_repo_principal
}
