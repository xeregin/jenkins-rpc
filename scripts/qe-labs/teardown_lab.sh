#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1

# run the correct plays to teardown the lab
ansible-playbook -i LAB_ID playbooks/qe-labs/teardown_lab.yml $@ 2>&1
