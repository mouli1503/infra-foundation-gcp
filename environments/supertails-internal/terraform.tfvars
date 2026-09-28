
project_id = "sup-internal-apps"
region     = "asia-south1"
domain     = "apps.internal.supertails.com"

routes = {
  decision-engine = "crm-decision-engine"
  decision-engine-staging = "crm-decision-engine-staging"
  pma = "performance-marketing-agent"
  pma-staging = "performance-marketing-agent-staging"
  cx-analysts-api="cx-data-analysts"
  cx-analysts-api-staging="cx-data-analysts-staging"
  henlo-creative="henlo-creative"
  atlas = "atlas"
  category="dropship-ops-automator"
  pma-v2-staging = "pma-v2-frontend-staging"
  pma-v2-api-staging = "pma-v2-api-staging"
  "api.comos" = "comms-os-backend"
  "portal.comos" = "comms-os-frontend"
  "portal.pricing-engine" = "pricing-engine"
  shopify-proxy           = "shopify-proxy"
  breach-explorer         = "breach-explorer"
  "api.scribe" = "scribe-api-server"
  "api.retention" = "retention-dashboard-backend"
  "portal.retention" = "retention-dashboard-frontend"
}

iap_callback_route = null

iap_protected_routes = ["decision-engine", "decision-engine-staging", "pma", "pma-staging", "cx-analysts-api", "cx-analysts-api-staging", "henlo-creative", "category", "pma-v2-staging", "pma-v2-api-staging", "portal.pricing-engine", "shopify-proxy", "breach-explorer", "portal.comos", "portal.retention"]

iap_oauth_client_id             = "158581135398-eft452itu9n28iko8ooevml29c3pp3t8.apps.googleusercontent.com"
iap_oauth_client_secret_secret_id = "iap-oauth-client-secret"

iap_access_members = [
  "group:product_team@supertails.com"
]

iap_route_access = {
  "decision-engine" = ["group:product_team@supertails.com", "group:crm-decision-engine@supertails.com", "serviceAccount:scheduler-decision-engine@sup-internal-apps.iam.gserviceaccount.com", "serviceAccount:cloud-scheduler@sup-internal-apps.iam.gserviceaccount.com"]
  "decision-engine-staging" = ["group:product_team@supertails.com", "group:crm-decision-engine@supertails.com"]
  "pma" = ["group:product_team@supertails.com", "group:crm-decision-engine@supertails.com"]
  "pma-staging" = ["group:product_team@supertails.com", "group:crm-decision-engine@supertails.com"]
  "cx-analysts-api" = ["group:product_team@supertails.com", "group:cx.apps@supertails.com"]
  "cx-analysts-api-staging" = ["group:product_team@supertails.com", "group:cx.apps@supertails.com"]
  "henlo-creative" = ["group:product_team@supertails.com", "user:stalinlovespets@supertails.com"]
  "category": ["group:product_team@supertails.com", "group:dropship-ops@supertails.com","domain:supertails.com" ]
  "pma-v2-staging" = ["domain:supertails.com"]
  "pma-v2-api-staging" = ["domain:supertails.com"]
  "portal.pricing-engine" = ["domain:supertails.com"]
  "shopify-proxy" = ["domain:supertails.com", "user:nabheet.scn@gmail.com", "user:msbinarydev@gmail.com", "user:baburakesh2308@gmail.com"]
  "breach-explorer" = ["domain:supertails.com"]
  "portal.comos" = ["domain:supertails.com"]
  "portal.retention" = ["domain:supertails.com"]
}
