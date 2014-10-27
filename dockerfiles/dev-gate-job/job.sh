#!/usr/bin/env bash

set -e
set -x

# Set HOME to /root
export HOME=/root

# Switch to home directory
cd

# We haven't trapped yet
trapped=0

# Trap setter; passes signal name as $1
set_trap() {
      func=$1; shift
  for sig; do
    trap "$func $sig" "$sig"
  done
}

# Cleanup trap
cleanup() {
  # If first trap
  if [[ $trapped -eq 0 ]]
  then
    # We've trapped now
    trapped=1
    # Store exit code
    case $1 in
      INT|TERM|ERR)
        retval=1;; # exit 1 on INT, TERM, ERR
      *)
        retval=$1;; # specified code otherwise
    esac
    # Kill process group, retriggering trap
    kill 0
  fi
  # Disable trap
  trap - INT TERM ERR

  # Rekick the nodes in preperation for the next run.
  [ -e playbooks ] || pushd jenkins-rpc
  [[ $REKICK == "yes" ]] &&  ansible-playbook -i inventory/dev-sat6-lab01 -e CLUSTER_NUMBER=${EXECUTOR_NUMBER}  playbooks/dev-labs/clean.yml ||:

  # Exit
  exit $retval
}

# Set the trap
set_trap cleanup INT TERM ERR

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git & wait %1

# Move into jenkins-rpc
pushd jenkins-rpc

# Run the lab prep playbook
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1
[[ $BUILD == "yes" ]] && ansible-playbook -i inventory/dev-sat6-lab01 -e hosts=cluster${EXECUTOR_NUMBER} -e pullRequestID=${ghprbPullId} playbooks/dev-labs/site.yml & wait %1
popd

# Skip deployment and trigger success handler
[[ $BUILD != "yes" ]] && cleanup 0

# Connect to target and run script - this will kickoff ansible-lxc-rpc
ssh $(<target.ip) ./target.sh & wait %1
# Trigger success handler

cleanup 0
