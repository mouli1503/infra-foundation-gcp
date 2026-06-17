# SuperTails Internal Apps - STAGING
# Populate `routes` and the IAP fields when you start migrating services.
# Until then, `terraform plan/apply` will fail (routes is required and must be non-empty).

project_id = "internal-apps-staging"
region     = "asia-south1"
domain     = "apps.staging.supertails.com"

# Add Cloud Run services here as you migrate, e.g.
# routes = {
#   hello = "hello-staging"
# }
routes = {
    inv-engine = "inventory-engine"
    pricing-engine = "pricing-engine"
    demo = "hello"
    pricing-engine-prod = "pricing-engine-prod"
    cp = "cost-provision-console-prod"
}

iap_callback_route = null

# Add the route keys that should be IAP-protected, e.g. ["hello"]
iap_protected_routes = ["demo", "inv-engine", "pricing-engine", "pricing-engine-prod", "cp"]

# Create an OAuth 2.0 Client ID in this project (APIs & Services -> Credentials),
# then store its secret in Secret Manager under the name below.
iap_oauth_client_id               = "709627498570-9mro1usmim3srd9gjl916nvgjfab82iv.apps.googleusercontent.com"
iap_oauth_client_secret_secret_id = "iap-oauth-client-secret"

# Default IAP members for any protected route not listed in `iap_route_access`.
iap_access_members = []

# Per-route IAP access overrides, e.g.
# iap_route_access = {
#   "hello" = ["group:product_team@supertails.com"]
# }
iap_route_access = {
    "demo" = ["group:product_team@supertails.com", "serviceAccount:scheduler-inv-engine@internal-apps-staging.iam.gserviceaccount.com"]
    "inv-engine" = ["group:product_team@supertails.com", "domain:supertails.com", "serviceAccount:scheduler-inv-engine@internal-apps-staging.iam.gserviceaccount.com"]
    "pricing-engine" = ["group:product_team@supertails.com", "domain:supertails.com"]
    "pricing-engine-prod" = ["group:product_team@supertails.com", "domain:supertails.com"]
    "cp" = ["group:product_team@supertails.com", "domain:supertails.com"]
}
