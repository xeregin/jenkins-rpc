
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
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/infrastructure/haproxy-install.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/setup-everything.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/swift-all.yml; arc
ansible-playbook -e @/root/rpc_deploy/user_variables.yml playbooks/openstack/tempest.yml; arc
ansible "utility_all[0]" -m shell -a /root/rpc_tempest_gate.sh; arc
popd

exit $rc
