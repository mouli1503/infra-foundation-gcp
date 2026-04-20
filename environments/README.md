# Environments (separate directories)

Each subdirectory is a self-contained Terraform config for a different GCP project.

| Directory | Project |
|-----------|---------|
| `supertails-internal/` | SuperTails Internal Apps (sup-internal-apps) |
| `supertails-vc/` | SuperTailsVC |

## Deploy to SuperTails Internal Apps

```bash
cd environments/supertails-internal
terraform init
terraform plan
terraform apply
```

## Deploy to SuperTailsVC

1. Edit `terraform.tfvars` with your project ID, domain, routes, and IAP config.
2. Create the GCP project and enable required APIs if needed.
3. Run:

```bash
cd environments/supertails-vc
terraform init
terraform plan
terraform apply
```

## Notes

- Each environment has its own state (no workspaces needed).
- Changes in one directory do not affect the other.
- Route keys must be lowercase with hyphens (e.g. `decision-engine` not `decisionEngine`).
