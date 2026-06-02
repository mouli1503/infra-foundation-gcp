# Terraform multi-project deployment (separate directories)
# Usage: make plan-internal | apply-internal | plan-vc | apply-vc

.PHONY: plan-internal apply-internal plan-vc apply-vc init-internal init-vc plan-internal-staging apply-internal-staging
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
