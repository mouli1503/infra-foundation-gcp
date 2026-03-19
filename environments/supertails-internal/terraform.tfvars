
project_id = "sup-internal-apps"
region     = "asia-south1"
domain     = "apps.internal.supertails.com"

routes = {
  hello           = "hello"
  hello21         = "hello-21"
  testing         = "testing-repo1"
  decision-engine = "crm-decision-engine"
}

iap_callback_route = "hello"

iap_protected_routes = ["hello", "hello21", "testing", "decision-engine"]

iap_oauth_client_id             = "158581135398-eft452itu9n28iko8ooevml29c3pp3t8.apps.googleusercontent.com"
iap_oauth_client_secret_secret_id = "iap-oauth-client-secret"

iap_access_members = [
  "group:product_team@supertails.com"
]

iap_route_access = {
  "hello"           = ["group:category@supertails.com"]
  "hello21"         = ["group:category@supertails.com"]
  "testing"         = ["group:product_team@supertails.com"]
  "decision-engine" = ["group:product_team@supertails.com", "group:crm-decision-engine@supertails.com"]
}
