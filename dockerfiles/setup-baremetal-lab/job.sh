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

# Job commands follow

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

# Add '& wait' to every long-running job command
# Example: ansible-playbook blah & wait
