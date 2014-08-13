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

# Add '& wait' to every long-running job command
# Example: ansible-playbook blah & wait
