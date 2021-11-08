SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

TERRAFORM := $(SELF)/bin/terraform

SSH_OPTIONS := -o ForwardAgent=yes \
               -o StrictHostKeyChecking=no \
               -o GlobalKnownHostsFile=/dev/null \
               -o UserKnownHostsFile=/dev/null

export

.PHONY: all requirements \
        binaries extras \
        opennebula-disk \
        opennebula \
        guest \
        destroy \
        clean \
        ssh ssh-guest

all:

requirements: binaries extras

binaries:
	@make -f $(SELF)/Makefile.BINARIES

extras:
	@make -f $(SELF)/Makefile.EXTRAS

opennebula-disk:
	@cd $(SELF)/packer/opennebula/ && make build

opennebula: opennebula-disk
	@cd $(SELF)/terraform/opennebula/ && $(TERRAFORM) init
	@cd $(SELF)/terraform/opennebula/ && $(TERRAFORM) apply

# FIXME
guest: opennebula
	@cd $(SELF)/terraform/guest/ && $(TERRAFORM) init
	@cd $(SELF)/terraform/guest/ && if $(TERRAFORM) state list | wc -l | (read LC && [[ $$LC -lt 1 ]]); then \
	  $(TERRAFORM) apply -var first_run=true; \
	  $(TERRAFORM) apply; \
	else \
	  $(TERRAFORM) apply; \
	fi

destroy:
	@cd $(SELF)/terraform/guest/ && $(TERRAFORM) init
	@cd $(SELF)/terraform/guest/ && $(TERRAFORM) destroy
	@cd $(SELF)/terraform/opennebula/ && $(TERRAFORM) init
	@cd $(SELF)/terraform/opennebula/ && $(TERRAFORM) destroy

clean:
	@-make clean -f $(SELF)/Makefile.BINARIES
	@-make clean -f $(SELF)/Makefile.EXTRAS
	@-cd $(SELF)/packer/opennebula/ && make clean

ssh:
	@ssh $(SSH_OPTIONS) root@10.11.12.13

ssh-guest:
	@ssh $(SSH_OPTIONS) root@10.11.12.13 -t sudo -iu oneadmin ssh root@172.16.100.2
