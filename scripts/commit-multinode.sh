#!/usr/bin/env bash

CLUSTER_NUMBER=${CLUSTER_NUMBER:-1}
TAGS=${TAGS:-prepare,run,test}
OS_ANSIBLE_BRANCH=${OS_ANSIBLE_BRANCH:-juno}
GERRIT_REFSPEC=${GERRIT_REFSPEC:-refs/changes/87/139087/14}
ANSIBLE_OPTIONS=${ANSIBLE_OPTIONS:--v}

ansible-playbook \
  -i inventory/commit-cluster-$CLUSTER_NUMBER\
  -e@vars/packages.yml\
  -e@vars/pip.yml\
  -e@vars/kernel.yml\
  -e@vars/commit-multinode.yml\
  -e cluster_number=${CLUSTER_NUMBER}\
  -e GERRIT_REFSPEC=${GERRIT_REFSPEC}\
  -e os_ansible_branch=${OS_ANSIBLE_BRANCH}\
  --tags $TAGS\
  $ANSIBLE_OPTIONS\
  commit-multinode.yml


