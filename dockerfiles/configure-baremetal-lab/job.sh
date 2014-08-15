#!/usr/bin/env bash

set -e
set -x

# Set HOME to /root
export HOME=/root

# Switch to home directory
cd

# Cleanup function
cleanup() {
  trap - TERM
  kill 0
  # Put any other cleanup here
}
trap cleanup TERM

## Job commands follow

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git & wait || true

# Fire up jenkins-rpc
pushd jenkins-rpc

# Place users keys on all hosts
./scripts/qe-labs/sshkeys.sh --file ~/keys.json & wait

# Skip deployment and trigger handler
[[ $BUILD_SKIP == "yes" ]] && cleanup

# Add '& wait' to every long-running job command
./scripts/qe-labs/configure_lab.sh & wait
