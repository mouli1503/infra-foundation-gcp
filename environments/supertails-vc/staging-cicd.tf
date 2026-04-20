module "staging_cicd_github_oidc" {
  source = "../../modules/staging-cicd-github-oidc"

  enable                        = var.enable_staging_cicd
  project_id                    = var.project_id
  region                        = var.region
  project_number                = var.project_number
  workload_identity_pool_id     = var.workload_identity_pool_id
  workload_identity_provider_id = var.workload_identity_provider_id
  github_repository             = var.github_repository
  staging_deploy_sa_account_id  = var.staging_deploy_sa_account_id
  jobs_invoker_sa_account_id    = var.jobs_invoker_sa_account_id
  cloud_run_job_names           = var.cloud_run_job_names

  depends_on = [google_project_service.apis]
}
