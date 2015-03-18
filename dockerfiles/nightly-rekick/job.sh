#!/usr/bin/env bash

set -e
set -x

env

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
  trap - INT TERM ERR

  # Exit
  exit $retval
}

rekick() {
  # teardown the lab
  pushd jenkins-rpc
  git checkout $RELEASE

  export PYTHONUNBUFFERED=1
  export ANSIBLE_FORCE_COLOR=1

  ansible-playbook \
    -i playbooks/inventory/$LAB \
    -e @playbooks/vars/$LAB.yml \
    playbooks/rekick-lab.yml & wait %1

  popd
}

# Set the trap
set_trap cleanup INT TERM ERR

# Clone jenkins-rpc repo
git clone git@github.com:rcbops/jenkins-rpc.git & wait %1

# rekick lab
rekick

# Exit cleanly
exit 0
