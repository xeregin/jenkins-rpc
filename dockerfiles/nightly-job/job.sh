#!/usr/bin/env bash

set -e
set -x

env

# Set HOME to /root
export HOME=/root

# Switch to home directory
cd

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git & wait %1

if [[ $BUILD == "yes" ]]
then
  # Move into jenkins-rpc
  pushd jenkins-rpc
 
  # Set color and buffer
  export PYTHONUNBUFFERED=1
  export ANSIBLE_FORCE_COLOR=1

  # Preconfigure the lab
  ansible-playbook \
    -i inventory/$LAB \
    -e @vars/$LAB \
    playbooks/nightly-labs/configure-hosts.yml & wait %1

  # Configure RPC
  ansible-playbook \
  -i inventory/$LAB
  -e @vars/$LAB \
  playbooks/nightly-labs/configure-rpc.yml & wait %1

  popd

  # Build RPC
  ssh $(<target.ip) ./target.sh & wait %1
fi

