#!/usr/bin/env bash
set -x

export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1

#Add Return Code
arc(){
  rc=$(($rc + $?))
}

rc=0

pushd ansible-lxc-rpc/rpc_deployment

# fail fast on anything that exits with an error level > 0
set -e

ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/infrastructure/haproxy-install.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/setup/host-setup.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/infrastructure/infrastructure-setup.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/keystone-all.yml; arc

# no longer fail fast from now on - just continue
set +e

ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/glance-all.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/heat-all.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/nova-all.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/neutron-all.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/cinder-all.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/horizon-all.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/utility-all.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/rpc-support-all.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/infrastructure/rsyslog-config.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/tempest.yml; arc
ansible "utility_all[0]" -m shell -a /root/rpc_tempest_gate.sh; arc
popd

exit $rc
