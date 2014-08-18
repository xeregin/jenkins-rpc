#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1

# run the correct plays to test the lab
ansible-playbook -i LAB_ID playbooks/qe-labs/test_lab.yml $@ 2>&1
