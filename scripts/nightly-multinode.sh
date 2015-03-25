#!/usr/bin/env bash
LAB=${LAB:-master}
TAGS=${TAGS:-prepare,run,test}
OS_ANSIBLE_BRANCH=${OS_ANSIBLE_BRANCH:-master}
ANSIBLE_OPTIONS=${ANSIBLE_OPTIONS:--v}

ansible-playbook \
  -i inventory/nightly-${LAB} \
  -e @vars/nightly-${LAB}.yml \
  -e os_ansible_branch=${OS_ANSIBLE_BRANCH} \
  --tags $TAGS \
  $ANSIBLE_OPTIONS \
  nightly-multinode.yml
