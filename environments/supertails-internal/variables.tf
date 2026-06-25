
variable "project_id" {
  type = string
}
variable "region" {
  type    = string
  default = "asia-south1"
}
variable "domain" {
  type    = string
  default = "apps.internal.supertails.com"
}

variable "routes" {
  description = "Map of route_key (subdomain) -> Cloud Run service name. e.g. hello -> hello.apps.internal.supertails.com"
  type        = map(string)
}

variable "iap_protected_routes" {
  description = "Routes that require IAP authentication"
  type        = set(string)
  default     = []
}

variable "iap_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "iap_oauth_client_secret_secret_id" {
  description = "Secret Manager secret containing IAP client secret"
  type        = string
}

variable "iap_access_members" {
  description = "Default IAP members (used for routes not in iap_route_access)"
  type        = set(string)
  default     = []
}

variable "iap_route_access" {
  description = "Per-route IAP access: route_key -> set of members. Overrides iap_access_members for that route."
  type        = map(set(string))
  default     = {}
}

variable "secrets" {
  description = "Secret Manager secrets to create in this project: secret_id => secret value. Values supplied via gitignored secrets.auto.tfvars. Not marked sensitive at the variable level (sensitive vars can't be used in for_each); the values are redacted in plan/apply because secret_version.secret_data is sensitive and wrapped in sensitive()."
  type        = map(string)
  default     = {}
}

variable "secret_accessors" {
  description = "Default members granted roles/secretmanager.secretAccessor on every secret (e.g. the Cloud Run runtime service account, serviceAccount:...@sup-internal-apps.iam.gserviceaccount.com)."
  type        = set(string)
  default     = []
}

variable "secret_access_overrides" {
  description = "Per-secret accessor overrides: secret_id => set of members. Overrides secret_accessors for that secret only."
  type        = map(set(string))
  default     = {}
}

variable "default_route" {
  description = "Route key for default_service (unmatched paths). Unset = first route."
  type        = string
  default     = null
}

variable "iap_callback_route" {
  description = "Route key that receives GET / (IAP callback). Must be an IAP-protected route (e.g. 'hello') so IAP validates the token and redirects back to the app; that backend must return 200 for GET /."
  type        = string
  default     = null
}
