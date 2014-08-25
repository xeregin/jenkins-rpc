#!/usr/bin/env bash

set -e
set -x

# Set HOME to /root
export HOME=/root

# Switch to home directory
cd

# Cleanup function
cleanup() {
  # Store return value
  retval=$?
  # Disable trap
  trap - INT TERM EXIT
  # Kill process group to catch jobs
  kill 0
  # Exit if we're keeping the build
  [[ $BUILD_KEEP == "yes" ]] && exit $retval
  # Otherwise cleanup
  # Exit
  exit $retval
}
trap cleanup INT TERM EXIT

# Clone jenkins-rpc repo
git clone -b dev-sat6 git@github.com:Apsu/jenkins-rpc.git & wait || true

# Fire up jenkins-rpc
pushd jenkins-rpc
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1
ansible-playbook -i inventory/dev-sat6-lab01 -e hosts=cluster${EXECUTOR_NUMBER} playbooks/dev-labs/site.yml & wait
popd

# Skip deployment and trigger handler
[[ $BUILD_SKIP == "yes" ]] && cleanup

# Connect to target and run script
ssh $(<target.ip) ./target.sh & wait
