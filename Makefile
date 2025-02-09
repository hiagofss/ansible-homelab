PLAYBOOK_NAME=

.PHONY: inventory-list
inventory-list:
	@ansible-inventory -i inventory.yaml --list
.PHONY: ping
ping:
	@export $(grep -v '^#' .env | xargs)
	@ansible -m ping -i inventory.yaml all -vvvv
.PHONY: check
check:
	@export $(grep -v '^#' .env | xargs)
	@ansible-playbook -i inventory.yaml playbooks/update.yaml --check --diff
.PHONY: run
run:
	@export $(grep -v '^#' .env | xargs)
	@ansible-playbook -i inventory.yaml playbooks/update.yaml -vvvv
