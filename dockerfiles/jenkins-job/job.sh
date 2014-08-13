#!/usr/bin/env bash

set -e
set -x

# Set HOME to /root
export HOME=/root

# Switch to home directory
cd

# Cleanup function
cleanup() {
  pushd ~/jenkins-rpc
  ./destroy.sh
}
trap cleanup 0

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git || true

# Fire up jenkins-rpc
pushd jenkins-rpc
cp ~/.ssh/id_* roles/configure-hosts/files/
./deploy.sh
popd
