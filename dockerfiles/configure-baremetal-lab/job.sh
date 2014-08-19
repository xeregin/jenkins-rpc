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
  ./scripts/qe-labs/destroy.sh
}
trap cleanup INT TERM EXIT

## Job commands follow

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git & wait || true

# Fire up jenkins-rpc
pushd jenkins-rpc

# Place users keys on all hosts
python ./scripts/qe-labs/sshkeys.py --file ~/keys.json & wait

# Skip deployment and trigger handler
[[ $BUILD_SKIP == "yes" ]] && cleanup

# Add '& wait' to every long-running job command
./scripts/qe-labs/configure_lab.sh & wait
