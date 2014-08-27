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
  trap - INT TERM
  # Exit
  exit $retval
}

# Set the trap
set_trap cleanup INT TERM ERR

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git & wait %1

# Move into jenkins-rpc
pushd jenkins-rpc
# Add pull-request fetch refspec
git config --add remote.origin.fetch "+refs/pull/*/head:refs/remotes/origin/pr/*"
# Fetch the pull requests
git fetch origin
# Checkout the pull request
git checkout pr/${ghprbPullId}

# Fire up the ansibles
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1
ansible-playbook -i inventory/dev-sat6-lab01 -e hosts=cluster${EXECUTOR_NUMBER} playbooks/dev-labs/site.yml & wait %1
popd

# Skip deployment and trigger success handler
[[ $BUILD_SKIP == "yes" ]] && cleanup 0

# Connect to target and run script
ssh $(<target.ip) ./target.sh & wait %1
# Trigger success handler
cleanup 0
