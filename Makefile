# Terraform multi-project deployment (separate directories)
# Usage: make plan-internal | apply-internal | plan-vc | apply-vc

.PHONY: plan-internal apply-internal plan-vc apply-vc init-internal init-vc plan-internal-staging apply-internal-staging iap-drift-internal iap-sync-internal
# SuperTails Internal Apps
init-internal:
	cd environments/supertails-internal && terraform init

plan-internal:
	cd environments/supertails-internal && terraform plan

apply-internal:
	cd environments/supertails-internal && terraform apply

# SuperTailsVC
init-vc:
	cd environments/supertails-vc && terraform init

plan-vc:
	cd environments/supertails-vc && terraform plan

apply-vc:
	cd environments/supertails-vc && terraform apply


plan-internal-staging:
	cd environments/supertails-internal-staging && terraform plan

apply-internal-staging:
	cd environments/supertails-internal-staging && terraform apply

# The iap_access binding is authoritative: IAP members granted via gcloud get
# revoked on the next apply. Check for those before every apply-internal.
iap-drift-internal:
	./scripts/sync-iap-access.py

# Same, but writes the live members back into terraform.tfvars.
iap-sync-internal:
	./scripts/sync-iap-access.py --write
