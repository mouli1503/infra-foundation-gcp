# ── Secret Manager ───────────────────────────────────────────────────────────
# Secrets for this project (sup-internal-apps).
#
# The app resolves secrets at runtime via env_loader.bootstrap(), which fetches
# hardcoded, UNSUFFIXED names (pe-db-url, pe-cron-secret, pe-analytics-db-*, etc.)
# from the service's own GCP project. So prod secrets live here, unsuffixed.
#
# Values are supplied via secrets.auto.tfvars (GITIGNORED — never commit real
# values). Terraform creates the secret container AND its first version, so the
# value lands in Terraform state. State lives in the GCS backend
# (sup-internal-apps-tfstate), encrypted at rest — keep that bucket locked down.

resource "google_secret_manager_secret" "secrets" {
  for_each  = var.secrets
  project   = var.project_id
  secret_id = each.key

  replication {
    auto {}
  }

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "versions" {
  for_each    = var.secrets
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = sensitive(each.value)
}

locals {
  # Effective accessors per secret: per-secret override, else the default set.
  secret_access = {
    for sid in keys(var.secrets) : sid => tolist(lookup(var.secret_access_overrides, sid, var.secret_accessors))
  }

  # Flatten {secret_id => [members]} into one binding per (secret, member).
  secret_iam_bindings = merge([
    for sid, members in local.secret_access : {
      for m in members : "${sid}::${m}" => { secret_id = sid, member = m }
    }
  ]...)
}

resource "google_secret_manager_secret_iam_member" "accessors" {
  for_each = local.secret_iam_bindings

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_id].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member
}
