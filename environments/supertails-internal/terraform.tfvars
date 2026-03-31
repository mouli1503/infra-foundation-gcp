
project_id = "sup-internal-apps"
region     = "asia-south1"
domain     = "apps.internal.supertails.com"

routes = {
  decision-engine = "crm-decision-engine"
  decision-engine-staging = "crm-decision-engine-staging"
  pma = "performance-marketing-agent"
  pma-staging = "performance-marketing-agent-staging"
}

iap_callback_route = null

iap_protected_routes = ["decision-engine", "decision-engine-staging", "pma", "pma-staging"]

iap_oauth_client_id             = "158581135398-eft452itu9n28iko8ooevml29c3pp3t8.apps.googleusercontent.com"
iap_oauth_client_secret_secret_id = "iap-oauth-client-secret"

iap_access_members = [
  "group:product_team@supertails.com"
]

iap_route_access = {
  "decision-engine" = ["group:product_team@supertails.com", "group:crm-decision-engine@supertails.com"]
  "decision-engine-staging" = ["group:product_team@supertails.com", "group:crm-decision-engine@supertails.com"]
  "pma" = ["group:product_team@supertails.com", "group:crm-decision-engine@supertails.com"]
  "pma-staging" = ["group:product_team@supertails.com", "group:crm-decision-engine@supertails.com"]
}
