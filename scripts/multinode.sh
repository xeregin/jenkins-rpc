#!/usr/bin/env bash

# This script prepares, deploys, and tests the `rpc-openstack` and
# `os-ansible-deployment` projects within a variety of environments. Each func-
# tion corresponds to a Ansible role within the `multinode.yml` playbook.

# They're run in a set order and perform documented installation steps until
# they either complete or fail. The idea of the tag system is to be able to
# have flexible jenkins jobs, without complex job relationships in jenkins.


## Job-centric variables
LAB=${LAB:-master}
LAB_PREFIX=${LAB_PREFIX:-nightly}
TAGS=${TAGS:-prepare run upgrade test}
PRODUCT=${PRODUCT:-os-ansible-deployment}
CONFIG_PREFIX=${CONFIG_PREFIX:-openstack}

## Jenkins-centric variables
PRODUCT_BRANCH=${PRODUCT_BRANCH:-master}
JENKINS_RPC_URL=${JENKINS_RPC_URL:-https://github.com/rcbops/jenkins-rpc}
JENKINS_RPC_BRANCH=${JENKINS_RPC_BRANCH:-master}
TEMPEST_SCRIPT_PARAMETERS=${TEMPEST_SCRIPT_PARAMETERS:-api}
ANSIBLE_FORCE_COLOR=${ANSIBLE_FORCE_COLOR:-1}
ANSIBLE_OPTIONS=${ANSIBLE_OPTIONS:--v}
UPGRADE=${UPGRADE:-NO}
UPGRADE_BRANCH=${UPGRADE_BRANCH:-master}
DEPLOY_MAAS=${DEPLOY_MAAS:-"no"}
DEPLOY_HAPROXY=${DEPLOY_HAPROXY:-"yes"}


env

function ssh_command {
  local command="$1"
  local infra01

  # Find the deployment node's IP address within a lab's inventory file
  OCTET='[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+'
  infra01="$(grep --only-matching --max-count=1 $OCTET \
     ./inventory/${LAB_PREFIX}-${LAB})"

  # Clear a temp environment file in-case we're already on the deployment node
  > /tmp/env
  echo "export ANSIBLE_FORCE_COLOR=${ANSIBLE_FORCE_COLOR}" >> script_env
  scp script_env $infra01:/tmp/env

  ssh root@$infra01 "source /tmp/env; ${command}"
}

function run_tag {
  export ANSIBLE_FORCE_COLOR
  local tag="$1"

  if [[ ${tag} == "prepare" ]]; then
    echo "Running ${tag} from multinode.yml with tags: ${tag}, ${PRODUCT}, and ${LAB_PREFIX}."
    ansible-playbook \
      --inventory-file="inventory/${LAB_PREFIX}-${LAB}" \
      --extra-vars="@vars/${LAB_PREFIX}-${LAB}.yml" \
      --extra-vars="product_repo_dir=${PRODUCT_REPO_DIR}" \
      --extra-vars="osad_repo_dir=${OSAD_REPO_DIR}" \
      --extra-vars="product_url=${PRODUCT_URL}" \
      --extra-vars="product_branch=${PRODUCT_BRANCH}" \
      --extra-vars="config_prefix=${CONFIG_PREFIX}" \
      --tags="${tag},${PRODUCT},${LAB_PREFIX}" \
      ${ANSIBLE_OPTIONS} \
      multinode.yml
  else
    echo "Running ${tag} from multinode.yml"
    ansible-playbook \
      --inventory-file="inventory/${LAB_PREFIX}-${LAB}" \
      --extra-vars="@vars/${LAB_PREFIX}-${LAB}.yml" \
      --extra-vars="product_repo_dir=${PRODUCT_REPO_DIR}" \
      --extra-vars="osad_repo_dir=${OSAD_REPO_DIR}" \
      --extra-vars="product_url=${PRODUCT_URL}" \
      --extra-vars="product_branch=${PRODUCT_BRANCH}" \
      --extra-vars="config_prefix=${CONFIG_PREFIX}" \
      --tags="${tag}" \
      ${ANSIBLE_OPTIONS} \
      multinode.yml
  fi
}

function run_script {
  local script="$1"

  echo "Running ${script} from ${PRODUCT_REPO_DIR}/scripts."
  ssh_command "cd ${PRODUCT_REPO_DIR}; bash scripts/${script}.sh"
}

function prepare {
  echo "Sleep 3 minutes for reboot"
  sleep 180

  run_tag prepare
}

function run {
  echo "Sleep 3 minutes for reboot"
  sleep 180

  echo "export DEPLOY_MAAS=${DEPLOY_MAAS}" > script_env
  echo "export DEPLOY_HAPROXY=${DEPLOY_HAPROXY}" >> script_env
  run_script $BUILD_SCRIPT_NAME
}

function upgrade {
  run_tag upgrade
  run_script $UPGRADE_SCRIPT_NAME
}

function test {
  echo "export TEMPEST_SCRIPT_PARAMETERS=${TEMPEST_SCRIPT_PARAMETERS}" > script_env

  # Due to rpc-openstack having osad as a git submodule
  # when we run the tests for deploying from rpc-openstack
  # we have to change the DIR that we start from
  PRODUCT_REPO_DIR=$OSAD_REPO_DIR
  run_script $TEST_SCRIPT_NAME
}

function rekick {
  run_tag rekick
}

function cleanup {
  run_tag cleanup
}

function main {
  local retval

  # Variables based products' respective documentation
  if [[ "${PRODUCT}" == "rpc-openstack" ]]; then
    BUILD_SCRIPT_NAME="deploy"
    UPGRADE_SCRIPT_NAME="upgrade"
    TEST_SCRIPT_NAME="run-tempest"
    PRODUCT_REPO_DIR="/opt/rpc-openstack"
    PRODUCT_URL="https://github.com/rcbops/rpc-openstack"
    OSAD_REPO_DIR="${PRODUCT_REPO_DIR}/os-ansible-deployment"

    if [[ "${LAB_PREFIX}" == "release" ]]; then
      DEPLOY_MAAS="yes"
      DEPLOY_HAPROXY="no"
    fi

  elif [[ "${PRODUCT}" == "os-ansible-deployment" ]]; then
    BUILD_SCRIPT_NAME="run-playbooks"
    UPGRADE_SCRIPT_NAME="run-upgrade"
    TEST_SCRIPT_NAME="run-tempest"
    OSAD_REPO_DIR="/opt/os-ansible-deployment"
    PRODUCT_REPO_DIR=$OSAD_REPO_DIR
    PRODUCT_URL="https://github.com/stackforge/os-ansible-deployment"
  else
    echo "Invalid product name. Choices: 'rpc-openstack' or 'os-ansible-deployment'"
    exit 1
  fi

  retval=0
  for tag in ${TAGS}
  do
    $tag || { retval=1; break; }
  done

  exit $retval
}

main "$@"
