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
  trap - TERM
  # Kill process group to catch jobs
  kill 0
  # Exit if we're keeping the build
  [[ $BUILD_KEEP == "yes" ]] && exit
  # Destroy cluster hosts
  pushd ~/jenkins-rpc
  ./destroy.sh
}
trap cleanup TERM

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git & wait || true

# Fire up jenkins-rpc
pushd jenkins-rpc
# Populate playbook files for SSH keys on targets
cp ~/.ssh/id_* roles/configure-hosts/files/
./deploy.sh & wait
popd

# Connect to target and run script
ssh $(<target.ip) ./target.sh & wait
