#!/usr/bin/env bash

set -e
set -x

# Set HOME to /root
export HOME=/root

# Switch to home directory
cd

# Cleanup function
cleanup() {
  # Disable trap
  trap - INT TERM EXIT
  # Kill process group to catch jobs
  kill 0
  # Exit if we're keeping the build
  [[ $BUILD_KEEP == "yes" ]] && exit
  # Destroy cluster hosts
  pushd ~/jenkins-rpc
  ./scripts/cloud-gate/destroy.sh
}
trap cleanup INT TERM EXIT

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git & wait || true

# Fire up jenkins-rpc
pushd jenkins-rpc

# Populate playbook files for SSH keys on targets
cp ~/.ssh/id_* roles/configure-hosts/files/
./scripts/deploy.sh & wait
popd

# Skip deployment and trigger handler
[[ $BUILD_SKIP == "yes" ]] && cleanup

# Connect to target and run script
ssh $(<target.ip) ./target.sh & wait
