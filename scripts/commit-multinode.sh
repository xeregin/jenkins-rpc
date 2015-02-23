#!/usr/bin/env bash

CLUSTER_NUMBER=${CLUSTER_NUMBER:-1}
TAGS=${TAGS:-prepare,run,test}
TARGET_BRANCH=${TARGET_BRANCH:-master}

ansible-playbook \
  -i inventory/commit-cluster-$CLUSTER_NUMBER\
  -e@vars/packages.yml\
  -e@vars/pip.yml\
  -e@vars/kernel.yml\
  -e@vars/commit-multinode.yml\
  -e targetBranch=${TARGET_BRANCH}\
  -e cluster_number=${CLUSTER_NUMBER}\
  --tags $TAGS\
  commit-multinode.yml


