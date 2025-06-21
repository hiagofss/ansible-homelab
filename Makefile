include .env
PLAYBOOK_NAME=

.PHONY: inventory-list
inventory-list:
	@ansible-inventory -i inventory.yaml --list
.PHONY: ping
ping:
	@export $(grep -v '^#' .env | xargs)
	@ansible -m ping -i inventory.yaml all -vvvv
.PHONY: update
update:
	@env $$(grep -v '^#' .env | xargs) ansible-playbook -i inventory.yaml playbooks/update.yaml  -v
sync:
	@env $$(grep -v '^#' .env | xargs) ansible-playbook -i inventory.yaml playbooks/rsync.ansible.yaml  -v
.PHONY: check
check:
	@export $(grep -v '^#' .env | xargs)
	@env $$(grep -v '^#' .env | xargs) ansible-playbook -i inventory.yaml playbooks/playbook_backupWorkspace.ansible.yaml --check --diff
.PHONY: run
run:
	@export $(grep -v '^#' .env | xargs)
	@env $$(grep -v '^#' .env | xargs) ansible-playbook -i inventory.yaml playbooks/playbook_backupWorkspace.ansible.yaml -v
