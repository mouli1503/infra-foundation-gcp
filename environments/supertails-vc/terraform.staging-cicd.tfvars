project_id  = "supertails-vc"
region      = "asia-south1"
project_number = "865435842415"
workload_identity_pool_id     = "github-actions"
workload_identity_provider_id = "github-oidc"
github_repository             = "SupertailsPCPL/performance-marketing-agent"

# Keep legacy WIF bootstrap disabled when using existing pool/provider IDs above.
enable_github_workload_identity = false

cloud_run_job_names = [
  "pma-v2-ingestion",
  "pma-v2-engine-cycle",
  "pma-v2-execute",
  "pma-v2-auto-revert",
  "pma-v2-outcome-tracker"
]
