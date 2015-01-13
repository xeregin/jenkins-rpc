
#!/usr/bin/env bash

set -e
set -x

export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1

pushd ansible-lxc-rpc/rpc_deployment
ansible-playbook -e @$HOME/rpc_deploy/user_variables.yml playbooks/setup/host-setup.yml
ansible-playbook -e @$HOME/rpc_deploy/user_variables.yml playbooks/infrastructure/infrastructure-setup.yml
ansible-playbook -e @$HOME/rpc_deploy/user_variables.yml playbooks/openstack/openstack-setup.yml
popd
