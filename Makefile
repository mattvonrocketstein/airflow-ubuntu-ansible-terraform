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

require-ansible:
	ansible --version &> /dev/null

require-tf:
	terraform --version &> /dev/null

require-jq:
	jq --version &> /dev/null

keypair:
	ssh-keygen -N '' -f airflow-key

plan: assert-TF_VAR_aws_profile require-tf require-keypair
	terraform plan

require-keypair:
	@ if [ -z "$TF_VAR_pub_key" ]; then \
		echo "\$TF_VAR_pub_key is empty; run 'make keypair' first!"; \
		exit 1; \
	fi

apply: assert-TF_VAR_aws_profile require-tf require-keypair
	terraform apply

ssh:
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
	 -i ./ec2-key -l ubuntu \
	 `terraform output -json|jq -r ".ip.value"`

plan-destroy:
	terraform plan -destroy

destroy:
	terraform destroy

clean: destroy

provision-%: require-jq require-tf
	ansible-playbook \
	 -e @ansible/vars.yml \
	 -i `terraform output -json|jq -r ".ip.value"`, \
	 ansible/$*.yml

reprovision: require-jq
	ansible-playbook \
	 -e @ansible/vars.yml \
	 -i `terraform output -json|jq -r ".ip.value"`, \
	 ansible/airflow.yml
