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

  # Preconfigure the lab
  export PYTHONUNBUFFERED=1
  export ANSIBLE_FORCE_COLOR=1
  ansible-playbook \
    -i inventory/$LAB \
    -e @vars/$LAB \
    playbooks/nightly-labs/configure-hosts.yml & wait %1

  popd
fi

