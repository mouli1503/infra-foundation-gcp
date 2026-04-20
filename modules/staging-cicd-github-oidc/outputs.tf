output "deploy_sa_email" {
  description = "Service account email for GitHub Actions staging deployer."
  value       = var.enable ? google_service_account.gha_staging_deploy[0].email : null
}

output "invoker_sa_email" {
  description = "Service account email used by Cloud Scheduler OIDC token for Cloud Run Jobs."
  value       = var.enable ? google_service_account.gha_jobs_invoker[0].email : null
}

output "gcp_wif_provider_full_name" {
  description = "Full Workload Identity Provider name for GitHub Actions auth."
  value       = local.gcp_wif_provider_full_name
}
