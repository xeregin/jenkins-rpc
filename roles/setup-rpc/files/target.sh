#!/usr/bin/env bash

set -e
set -x

export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1

pushd ansible-lxc-rpc/rpc_deployment
ansible-playbook -e @vars/user_variables.yml playbooks/all-the-all-the-things.yml 2>&1
popd
