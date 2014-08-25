#!/usr/bin/env bash

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
      INT|TERM)
        retval=1;; # exit 1 on INT or TERM
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
set_trap cleanup INT TERM

# Clone jenkins-rpc repo
git clone -b ${sha1} git@github.com:rcbops/jenkins-rpc.git & wait %1
[[ $retval -ne 0 ]] && cleanup 1

# Fire up jenkins-rpc
pushd jenkins-rpc
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1
ansible-playbook -i inventory/dev-sat6-lab01 -e hosts=cluster${EXECUTOR_NUMBER} playbooks/dev-labs/site.yml & wait %1
# Cleanup on error
[[ $? -ne 0 ]] && cleanup 2
popd

# Skip deployment and trigger handler
[[ $BUILD_SKIP == "yes" ]] && cleanup 0

# Connect to target and run script
ssh $(<target.ip) ./target.sh & wait %1
# Cleanup with return code
cleanup $?
