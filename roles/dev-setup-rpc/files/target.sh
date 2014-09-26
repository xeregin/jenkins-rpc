#!/usr/bin/env bash

set -e
set -x

export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1

pushd ansible-lxc-rpc/rpc_deployment
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/infrastructure/haproxy-install.yml
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/setup-everything.yml
popd
