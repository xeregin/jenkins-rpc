#!/usr/bin/env bash

set -e
set -x

# Set ansible tweaks
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1

# Set HOME to /root
export HOME=/root

# Switch to home directory
cd

# Cleanup function
cleanup() {
  pushd ~/jenkins-rpc
  ./destroy.sh
}
trap cleanup 0

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git

# Clone ansible-lx-rpc repo
git clone git@github.com:rcbops/ansible-lxc-rpc.git

# Install ansible and other RPC deps
pip install -r ansible-lxc-rpc/requirements.txt

# Fire up jenkins-rpc
pushd jenkins-rpc
./deploy.sh
popd

# Fire up RPC
pushd ansible-lxc-rpc/rpc_deployment
ansible-playbook -e @vars/user_variables.yml playbooks/all-the-all-the-things.yml
popd
