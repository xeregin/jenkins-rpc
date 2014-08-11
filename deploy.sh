#!/usr/bin/env bash

#[[ -d /opt/virtlab ]] && pushd /opt/virtlab
#source .venv/bin/activate
export PYTHONUNBUFFERED=1
export ANSIBLE_FORCE_COLOR=1
ansible-playbook deploy.yml $@ 2>&1
#[[ -d /opt/virtlab ]] && popd
