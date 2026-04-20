variable "enable" {
  description = "If true, provisions staging CI/CD IAM and GitHub OIDC bindings."
  type        = bool
  default     = true
}

variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run Jobs."
  type        = string
}

variable "project_number" {
  description = "Numeric GCP project number. Optional; derived from project_id when null."
  type        = string
  default     = null

  validation {
    condition     = var.project_number == null || can(regex("^[0-9]+$", var.project_number))
    error_message = "project_number must contain only digits when provided."
  }
}

variable "workload_identity_pool_id" {
  description = "Existing Workload Identity Pool ID (not full resource path)."
  type        = string
  default     = "github-actions"

  validation {
    condition     = !var.enable || trimspace(var.workload_identity_pool_id) != ""
    error_message = "workload_identity_pool_id is required when enable is true."
  }
}

variable "workload_identity_provider_id" {
  description = "Existing Workload Identity Provider ID (not full resource path)."
  type        = string
  default     = "github-oidc"

  validation {
    condition     = !var.enable || trimspace(var.workload_identity_provider_id) != ""
    error_message = "workload_identity_provider_id is required when enable is true."
  }
}

variable "github_repository" {
  description = "Exact GitHub repository in owner/repo format to trust via OIDC (no wildcard)."
  type        = string
  default     = "SupertailsPCPL/performance-marketing-agent"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be a single owner/repo value without wildcards."
  }
}

variable "staging_deploy_sa_account_id" {
  description = "Service account ID used by GitHub Actions for staging deploy/scheduler updates."
  type        = string
  default     = "gha-staging-deploy"
}

variable "jobs_invoker_sa_account_id" {
  description = "Service account ID used by Cloud Scheduler OIDC token to invoke Cloud Run Jobs."
  type        = string
  default     = "gha-jobs-invoker"
}

variable "cloud_run_job_names" {
  description = "Cloud Run Job names that should allow invocation from jobs_invoker SA."
  type        = set(string)
  default = [
    "pma-v2-ingestion",
    "pma-v2-engine-cycle",
    "pma-v2-execute",
    "pma-v2-auto-revert",
    "pma-v2-outcome-tracker"
  ]
}
