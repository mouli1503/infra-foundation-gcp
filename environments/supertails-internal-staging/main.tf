
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "iap.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudscheduler.googleapis.com"
  ])

  service            = each.value
  disable_on_destroy = false
}

# Provisions the IAP service agent in the project (fixes "IAP service account is not provisioned").
resource "google_project_service_identity" "iap_sa" {
  provider = google-beta

  project = var.project_id
  service = "iap.googleapis.com"

  depends_on = [google_project_service.apis]
}

data "google_secret_manager_secret_version" "iap_secret" {
  secret  = var.iap_oauth_client_secret_secret_id
  version = "latest"
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  for_each              = var.routes
  name                  = "neg-${each.key}"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = each.value
  }

  depends_on = [google_project_service.apis]
}

resource "google_compute_backend_service" "backend" {
  for_each              = var.routes
  name                  = "bs-${each.key}"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg[each.key].id
  }

  dynamic "iap" {
    for_each = contains(var.iap_protected_routes, each.key) ? [1] : []
    content {
      enabled              = true
      oauth2_client_id     = var.iap_oauth_client_id
      oauth2_client_secret = data.google_secret_manager_secret_version.iap_secret.secret_data
    }
  }
}

locals {
  route_keys              = keys(var.routes)
  effective_default_route = coalesce(var.default_route, local.route_keys[0])
  # Host-based: {route_key}.{domain} e.g. hello.apps.staging.supertails.com
  # route_host_overrides lets a route use an explicit FQDN that doesn't fit the
  # {route_key}.{domain} pattern (e.g. multi-label hosts like control-tower.api.apps.staging.supertails.com).
  # The route_key still drives GCP resource names (neg-/bs-/pm-) so it must stay dot-free.
  route_hosts = { for k in local.route_keys : k => lookup(var.route_host_overrides, k, "${k}.${var.domain}") }
}

resource "google_compute_url_map" "urlmap" {
  name = "apps-urlmap"

  default_service = google_compute_backend_service.backend[local.effective_default_route].id

  # Host rule per route: {route_key}.{domain} -> path matcher for that route
  # Only *.apps.staging.supertails.com (subdomains) in use; apex not used.
  dynamic "host_rule" {
    for_each = var.routes
    content {
      hosts        = [local.route_hosts[host_rule.key]]
      path_matcher = "pm-${host_rule.key}"
    }
  }

  # Path matcher per route: all paths go to that backend (no path rewrite)
  dynamic "path_matcher" {
    for_each = var.routes
    content {
      name            = "pm-${path_matcher.key}"
      default_service = google_compute_backend_service.backend[path_matcher.key].id
    }
  }
}

resource "google_compute_global_address" "lb_ip" {
  name = "apps-lb-ip"

  depends_on = [google_project_service.apis]
}

# Google managed SSL certs don't support wildcards; list each subdomain explicitly.
# Hash-based name avoids "already exists" when create_before_destroy replaces cert (e.g. adding routes)
resource "google_compute_managed_ssl_certificate" "cert" {
  name = "apps-mcert-${substr(sha256(join(",", sort(values(local.route_hosts)))), 0, 8)}"
  managed {
    domains = values(local.route_hosts)
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_project_service.apis]
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "apps-https-proxy"
  url_map          = google_compute_url_map.urlmap.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
}

resource "google_compute_global_forwarding_rule" "https_fr" {
  name                  = "apps-https-fr"
  ip_address            = google_compute_global_address.lb_ip.address
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  load_balancing_scheme = "EXTERNAL"
}

resource "google_iap_web_backend_service_iam_binding" "iap_access" {
  for_each = {
    for k in var.iap_protected_routes : k => k
  }

  web_backend_service = google_compute_backend_service.backend[each.key].name
  role                = "roles/iap.httpsResourceAccessor"
  members             = tolist(lookup(var.iap_route_access, each.key, var.iap_access_members))
}

data "google_project" "project" {
  project_id = var.project_id
}

# ── Cloud Scheduler service account for inv-engine ───────────────────────────

resource "google_service_account" "scheduler_inv_engine" {
  account_id   = "scheduler-inv-engine"
  display_name = "Cloud Scheduler – inv-engine"
  project      = var.project_id
}

resource "google_service_account_iam_member" "scheduler_sa_act_as" {
  service_account_id = google_service_account.scheduler_inv_engine.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

# HTTPS LB + serverless NEG: allow Google's Serverless robot to invoke each Cloud Run service.
resource "google_cloud_run_service_iam_member" "lb_serverless_neg_invoker" {
  for_each = var.routes

  project  = var.project_id
  location = var.region
  service  = each.value

  role   = "roles/run.invoker"
  member = "serviceAccount:service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com"

  depends_on = [google_project_service.apis]
}
