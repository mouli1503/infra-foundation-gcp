# SuperTailsVC - Update with your project config before applying

project_id = "supertails-vc" # Replace with actual SuperTailsVC project ID
region     = "asia-south1"
domain     = "apps.product.supertails.com" # Replace with your VC domain

routes = {
  # Add Cloud Run services: route_key = "cloud-run-service-name"
  # Use lowercase with hyphens for route keys (e.g. decision-engine not decisionEngine)
  # example = "example-service"
  atc         = "supertails-atc"
  atc-staging = "supertails-atc-staging"
  cx-helper   = "nugget-smartplug"
}

iap_callback_route = null # Set to route key if using IAP callback

iap_protected_routes = ["atc", "atc-staging"] # Add route keys that need IAP

iap_oauth_client_id               = "865435842415-n373i89u7p67po8l28totcv1ek4ba1nd.apps.googleusercontent.com"
iap_oauth_client_secret_secret_id = "iap-oauth-client-secret"

# Sign-in text "continue to …" = OAuth consent App name (Console: APIs & Services → OAuth consent screen → App name → e.g. SuperTails VC). Do not use google_iap_brand in Terraform here: one brand/project and API often returns 400 if it already exists; IAP brand API is deprecated.

iap_access_members = [
  "group:product_team@supertails.com"
]

iap_route_access = {
  "atc"         = ["group:product_team@supertails.com"]
  "atc-staging" = ["group:product_team@supertails.com"]
}

# GitHub Workload Identity Federation (CI/CD)
enable_github_workload_identity = true
github_workload_identity_repos  = ["SupertailsPCPL/*"]

