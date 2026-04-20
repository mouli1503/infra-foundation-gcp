output "deploy_sa_email" {
  description = "Service account email for GitHub Actions staging deployer."
  value       = module.staging_cicd_github_oidc.deploy_sa_email
}

output "invoker_sa_email" {
  description = "Service account email used by Cloud Scheduler OIDC token for Cloud Run Jobs."
  value       = module.staging_cicd_github_oidc.invoker_sa_email
}

output "gcp_wif_provider_full_name" {
  description = "Full Workload Identity Provider name for GitHub Actions auth."
  value       = module.staging_cicd_github_oidc.gcp_wif_provider_full_name
}
