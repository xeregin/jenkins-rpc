#!/usr/bin/env bash

set -e
set -x

export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1

pushd ansible-lxc-rpc/rpc_deployment
(
  set +e
  rc=0
  ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/infrastructure/haproxy-install.yml
  rc=$(($rc + $?))
  ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/setup-everything.yml
  rc=$(($rc + $?))
  ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/tempest.yml
  rc=$(($rc + $?))
  exit $rc
)
ansible_result=$?
ansible "utility_all[0]" -m shell -a /root/rpc_tempest_gate.sh
popd

#will have already exited failure if rpc_tempest_gate.sh failed, due to -e.
exit $ansible_result
