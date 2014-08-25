#!/usr/bin/env bash

set -x

# Set HOME to /root
export HOME=/root

# Switch to home directory
cd

# Cleanup function
cleanup() {
  retval=${1:-$?}
  # Disable trap
  trap - INT TERM
  # Kill jobs
  kill $(jobs -p)
  # Exit if we're keeping the build
  [[ $BUILD_KEEP == "yes" ]] && exit $retval
  # Otherwise cleanup
  # ...
  # Exit
  exit $retval
}
trap cleanup INT TERM

# Clone jenkins-rpc repo
git clone -b dev-sat6 git@github.com:Apsu/jenkins-rpc.git & wait
[[ $? -ne 0 ]] && cleanup

# Fire up jenkins-rpc
pushd jenkins-rpc
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1
ansible-playbook -i inventory/dev-sat6-lab01 -e hosts=cluster${EXECUTOR_NUMBER} playbooks/dev-labs/site.yml & wait
[[ $? -ne 0 ]] && cleanup
popd

# Skip deployment and trigger handler
[[ $BUILD_SKIP == "yes" ]] && cleanup 0

# Connect to target and run script
ssh $(<target.ip) ./target.sh & wait
cleanup $?
