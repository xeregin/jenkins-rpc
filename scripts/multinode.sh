#!/usr/bin/env bash

# This script prepares, deploys, and tests the `rpc-openstack` and
# `openstack-ansible` projects within a variety of environments. Each func-
# tion corresponds to a Ansible role within the `multinode.yml` playbook.

# They're run in a set order and perform documented installation steps until
# they either complete or fail. The idea of the tag system is to be able to
# have flexible jenkins jobs, without complex job relationships in jenkins.


## Job variables
LAB=${LAB:-master}
LAB_PREFIX=${LAB_PREFIX:-nightly}
TAGS=${TAGS:-rekick prepare run test}

## Jenkins variables
JENKINS_RPC_URL=${JENKINS_RPC_URL:-https://github.com/rcbops/jenkins-rpc}
JENKINS_RPC_BRANCH=${JENKINS_RPC_BRANCH:-master}

## Product Variables
PRODUCT=${PRODUCT:-openstack-ansible}
PRODUCT_URL=${PRODUCT_URL:-https://github.com/openstack/openstack-ansible.git}
PRODUCT_BRANCH=${PRODUCT_BRANCH:-master}

## Upgrade Variables
UPGRADE=${UPGRADE:-NO}
UPGRADE_PRODUCT=${UPGRADE_PRODUCT:-openstack-ansible}
UPGRADE_PRODUCT_URL=${UPGRADE_PRODUCT_URL:-https://github.com/openstack/openstack-ansible.git}
UPGRADE_PRODUCT_BRANCH=${UPGRADE_PRODUCT_BRANCH:-master}

## Deployment Variables
DEPLOY_MAAS=${DEPLOY_MAAS:-"no"}
DEPLOY_HAPROXY=${DEPLOY_HAPROXY:-"yes"}
DEPLOY_TEMPEST=${DEPLOY_TEMPEST:-"yes"}

# Product Config Variables
CONFIG_PREFIX=${CONFIG_PREFIX:-openstack}
TEMPEST_SCRIPT_PARAMETERS=${TEMPEST_SCRIPT_PARAMETERS:-api}

# Shell Variables
ANSIBLE_FORCE_COLOR=${ANSIBLE_FORCE_COLOR:-1}
ANSIBLE_OPTIONS=${ANSIBLE_OPTIONS:-"-v"}
FORKS=${FORKS:-10}

function find_infra01 {
  # Find the deployment node's IP address within a lab's inventory file
  OCTET='[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+'

  export infra01
  infra01="$(grep --only-matching --max-count=1 "$OCTET" \
     ./inventory/"$LAB_PREFIX"-"$LAB")"
}

function ssh_command {
  local command="$1"

  echo "export FORKS=${FORKS}" >> script_env
  echo "export ANSIBLE_FORCE_COLOR=${ANSIBLE_FORCE_COLOR}" >> script_env
  scp script_env "$infra01":/tmp/env

  # shellcheck disable=SC2029
  ssh root@"$infra01" "source /tmp/env; $command"
}

function run_tag {
  export ANSIBLE_FORCE_COLOR
  local tag="$1"

  env

  if [[ ${tag} == "prepare" ]]; then
    echo "Running tag ${tag} from multinode.yml with tags: ${tag}, ${PRODUCT}, and ${LAB_PREFIX}."
    ansible-playbook \
      --inventory-file="inventory/${LAB_PREFIX}-${LAB}" \
      --extra-vars="@vars/${LAB_PREFIX}-${LAB}.yml" \
      --extra-vars="product_repo_dir=${PRODUCT_REPO_DIR}" \
      --extra-vars="oa_repo_dir=${OA_REPO_DIR}" \
      --extra-vars="product_url=${PRODUCT_URL}" \
      --extra-vars="product_branch=${PRODUCT_BRANCH}" \
      --extra-vars="config_prefix=${CONFIG_PREFIX}" \
      --tags="${tag},${PRODUCT},${LAB_PREFIX}" \
      "$ANSIBLE_OPTIONS" \
      multinode.yml
  else
    echo "Running tag ${tag} from multinode.yml"
    ansible-playbook \
      --inventory-file="inventory/${LAB_PREFIX}-${LAB}" \
      --extra-vars="@vars/${LAB_PREFIX}-${LAB}.yml" \
      --extra-vars="product_repo_dir=${PRODUCT_REPO_DIR}" \
      --extra-vars="oa_repo_dir=${OA_REPO_DIR}" \
      --extra-vars="product_url=${PRODUCT_URL}" \
      --extra-vars="product_branch=${PRODUCT_BRANCH}" \
      --extra-vars="config_prefix=${CONFIG_PREFIX}" \
      --tags="${tag}" \
      "$ANSIBLE_OPTIONS" \
      multinode.yml
  fi
}

function run_script {
  local script="$1"

  echo "Running ${script} from ${PRODUCT_REPO_DIR}/scripts."

  # If we are running the upgrade we must echo YES into the script
  if [[ $tag == "upgrade" ]]; then
    ssh_command "cd ${PRODUCT_REPO_DIR}; echo \"YES\" | bash scripts/${script}.sh"
  else
    ssh_command "cd ${PRODUCT_REPO_DIR}; bash scripts/${script}.sh"
  fi
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
  echo "export DEPLOY_TEMPEST=${DEPLOY_TEMPEST}" >> script_env
  run_script "$BUILD_SCRIPT_NAME"
}

function upgrade {

  # Due to supporting both oa and rpc upgrade testing we need to override
  # all the PRODUCT variables to be correct.
  OLD_PRODUCT=$PRODUCT
  PRODUCT=$UPGRADE_PRODUCT
  PRODUCT_BRANCH=$UPGRADE_PRODUCT_BRANCH
  PRODUCT_URL=$UPGRADE_PRODUCT_URL
  CONFIG_PREFIX="openstack"

  if [[ "${OLD_PRODUCT}" == "openstack-ansible" ]] && [[ "${UPGRADE_PRODUCT}" == "rpc-openstack" ]]; then
    PRODUCT_REPO_DIR="/opt/${PRODUCT}"
    UPGRADE_SCRIPT_NAME="upgrade"
  fi

  # run upgrade tag in ansible
  run_tag upgrade
  run_script "$UPGRADE_SCRIPT_NAME"
}

function test {
  echo "export TEMPEST_SCRIPT_PARAMETERS=${TEMPEST_SCRIPT_PARAMETERS}" > script_env

  # Due to rpc-openstack having oa as a git submodule
  # when we run the tests for deploying from rpc-openstack
  # we have to change the DIR that we start from
  PRODUCT_REPO_DIR=$OA_REPO_DIR
  run_script "$TEST_SCRIPT_NAME"

  ssh_command "cd ${PRODUCT_REPO_DIR}/playbooks; ansible 'utility[0]' -m fetch -a 'src=/tmp/tempest_results.xml dest=/tmp/ flat=true'"
  scp "$infra01":/tmp/tempest_results.xml ~/tempest_results.xml
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
    PRODUCT_REPO_DIR="/opt/${PRODUCT}"
    PRODUCT_URL="https://github.com/rcbops/rpc-openstack"
    OA_REPO_DIR="${PRODUCT_REPO_DIR}/openstack-ansible"

    if [[ "${LAB_PREFIX}" == "release" ]]; then
      DEPLOY_HAPROXY="no"
    fi

  elif [[ "${PRODUCT}" == "openstack-ansible" ]]; then
    BUILD_SCRIPT_NAME="run-playbooks"
    UPGRADE_SCRIPT_NAME="run-upgrade"
    TEST_SCRIPT_NAME="run-tempest"
    OA_REPO_DIR="/opt/${PRODUCT}"
    PRODUCT_REPO_DIR=$OA_REPO_DIR
    PRODUCT_URL="https://github.com/openstack/openstack-ansible"
  else
    echo "Invalid product name. Choices: 'rpc-openstack' or 'openstack-ansible'"
    exit 1
  fi

  find_infra01

  retval=0
  for tag in ${TAGS}
  do
    $tag || { retval=1; break; }
  done

  exit $retval
}

main "$@"
