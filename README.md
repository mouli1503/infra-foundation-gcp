# Terraform: Cloud Run + HTTPS Load Balancer + IAP

## Architecture

Internet → HTTPS Load Balancer → URL Map → Backend Services → Cloud Run

**Host-based routing:** Each route = subdomain (e.g. hello.apps.internal.supertails.com → Cloud Run hello).

## Project structure (separate directories)

Terraform config lives under `environments/` — one directory per GCP project:

| Directory | Project |
|-----------|---------|
| `environments/supertails-internal/` | SuperTails Internal Apps (sup-internal-apps) |
| `environments/supertails-vc/` | SuperTailsVC |

See [environments/README.md](environments/README.md) for usage.

## Deploy

**SuperTails Internal Apps:**
```bash
cd environments/supertails-internal
terraform init
terraform plan
terraform apply
```

**SuperTailsVC:**
```bash
cd environments/supertails-vc
# Edit terraform.tfvars first
terraform init
terraform plan
terraform apply
```

## DNS (GoDaddy)

Add **wildcard** A record so subdomains resolve to the load balancer:

| Type | Host | Value |
|------|------|-------|
| A | `*.apps.internal` | `<load_balancer_ip>` from terraform output |

## IAP callback

After sign-in, IAP sends users to **GET /** with query params. That request must return **200** or the callback fails.

- Set `iap_callback_route` to a route that returns 200 for GET /.
- Use an IAP-protected route as default so users land on the right app after login.
