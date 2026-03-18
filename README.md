
# Terraform: Cloud Run + HTTPS Load Balancer + IAP

## Architecture
Internet → HTTPS Load Balancer → URL Map → Backend Services → Cloud Run

**Host-based routing (wildcard):** Each route = subdomain. No path rewrite, so IAP redirects work correctly.
- hello.apps.internal.supertails.com → Cloud Run hello
- testing.apps.internal.supertails.com → Cloud Run testing
- apps.internal.supertails.com (apex) → IAP callback / default

## Setup

1. Install Terraform
2. Authenticate to GCP

```
gcloud auth application-default login
```

3. Copy tfvars
```
cp terraform.tfvars.example terraform.tfvars
```

4. Run

```
terraform init
terraform plan
terraform apply
```

## DNS (GoDaddy)

Add **wildcard** A record so all subdomains resolve to the load balancer:

| Type | Host | Value |
|------|------|-------|
| A | `*.apps.internal` | `<load_balancer_ip>` from terraform output |

Optional: keep apex `apps.internal` → load balancer IP for apps.internal.supertails.com.

## IAP callback

After sign-in, IAP sends users to **GET /** with query params. That request must get **200** or the callback fails with 500.

1. Set iap_callback_route to a route that returns **200** for **GET /** (e.g. testing).
2. Prefer using an IAP-protected route as default (e.g. `default_route = "hello"`) so you don’t land on a different app after login. If you use a non-IAP route (e.g. `default_route = "testing"`), users may see that app after signing in instead of the one they requested.

## Add new Cloud Run route

Edit terraform.tfvars:

```
routes = {
  app1 = "cloudrun-app1"
  app2 = "cloudrun-app2"
  admin = "cloudrun-admin"
}
```

Run:
```
terraform apply
```
# infra-foundation-gcp
# infra-foundation-gcp
