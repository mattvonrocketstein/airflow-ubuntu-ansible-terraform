TF_VAR_aws_profile := 605-test
TF_VAR_pub_key := $(shell cat ./airflow-key.pub)
TF_VAR_aws_region := us-east-1
TF_VAR_aws_az := us-east-1d
TF_VAR_ami := ami-845367ff
ANSIBLE_ROLES_PATH := ./ansible/roles
ANSIBLE_CONFIG := ./ansible/ansible.cfg

export ANSIBLE_CONFIG ANSIBLE_ROLES_PATH
export TF_VAR_ami TF_VAR_aws_az TF_VAR_aws_profile
export TF_VAR_aws_region TF_VAR_pub_key

# An implicit guard target, used by other targets to ensure
# that environment variables are set before beginning tasks
assert-%:
	@ if [ "${${*}}" = "" ]; then \
	    echo "Environment variable $* not set"; \
	    exit 1; \
	fi

# A target to ensure fail-fast if ansible is not present
require-ansible:
	ansible --version &> /dev/null

# A target to ensure fail-fast if terraform is not present
require-tf:
	terraform --version &> /dev/null

# A target to ensure fail-fast if jq is not present
require-jq:
	jq --version &> /dev/null

# A target toe ensure fail-fast if keypair is not created
require-keypair:
	@ if [ -z "$$TF_VAR_pub_key" ]; then \
			echo "Pub key is empty; run 'make keypair' first!"; \
			exit 1; \
		fi;

# Helper for generating the keypair our instance will use
keypair:
	ssh-keygen -N '' -f airflow-key

# Various proxies for invoking common `terraform` subcommands with our
# specific environment.  The most important aspect of this is guaranteeing
# a consistent value for TF_VAR_aws_profile.
plan: assert-TF_VAR_aws_profile require-tf require-keypair
	terraform plan
apply: require-keypair assert-TF_VAR_aws_profile require-tf
	terraform apply
refresh: require-tf assert-TF_VAR_aws_profile
	terraform refresh
infrastructure: apply

# Aliases, prerequisites and proxies for invoking `terraform destroy`
# with the right environment.  This will show the plan and still ask
# for confirmation.
clean: destroy
plan-destroy:
	terraform plan -destroy
destroy: plan-destroy
	terraform destroy
teardown: destroy

# Helper for devs to SSH into the instance we're creating.
# This is only for inspection/debugging, it's not used directly
# in provisioning.
ssh:
	ssh -o UserKnownHostsFile=/dev/null \
		-o StrictHostKeyChecking=no \
	 	-i ./airflow-key -l ubuntu \
	 	`terraform output -json|jq -r ".ip.value"`

# Proxies for invoking ansible against the host created by terraform.
# This make target is parametric, i.e. `make provision-docker` will
# provision only with the playbook `ansible/docker.yml`, and
# `make provision-airflow` will provision only with the playbook
# `ansible/airflow.yml`.  To provision everything from scratch,
# use `make provision-main` or simply `make provision`
provision-%: require-jq require-tf require-ansible
	ansible-playbook \
	 -e @ansible/vars.yml \
	 -i `terraform output -json|jq -r ".ip.value"`, \
	 ansible/$*.yml
provision:
	make provision-main


# Proxies for running infrastructure tests.
test:
	ansible-playbook \
	 -e @ansible/vars.yml \
	 -i `terraform output -json|jq -r ".ip.value"`, \
	 ansible/test.yml

# Command and control proxies
backup: provision-backup
