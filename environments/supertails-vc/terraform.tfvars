# SuperTailsVC - Update with your project config before applying

project_id = "supertails-vc"  # Replace with actual SuperTailsVC project ID
region     = "asia-south1"
domain     = "apps.product.supertails.com"  # Replace with your VC domain

routes = {
  # Add Cloud Run services: route_key = "cloud-run-service-name"
  # Use lowercase with hyphens for route keys (e.g. decision-engine not decisionEngine)
  # example = "example-service"
  atc = "supertails-atc"

}

iap_callback_route = null  # Set to route key if using IAP callback

iap_protected_routes = []  # Add route keys that need IAP

iap_oauth_client_id             = "158581135398-eft452itu9n28iko8ooevml29c3pp3t8.apps.googleusercontent.com"
iap_oauth_client_secret_secret_id = "iap-oauth-client-secret"

iap_access_members = [
  "group:product_team@supertails.com"
]

iap_route_access = {
  "atc"         = ["group:product_team@supertails.com"]
}

