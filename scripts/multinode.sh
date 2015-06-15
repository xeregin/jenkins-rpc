#!/usr/bin/env bash

# TODO: Include overview

## Job centric variables
LAB=${LAB:-master}
LAB_PREFIX=${LAB_PREFIX:-nightly}
TAGS=${TAGS:-prepare run upgrade test}
PRODUCT=${PRODUCT:-osad}
REPO_DIR=${REPO_DIR:-"/opt/os-ansible-deployment"}
OSAD_REPO_DIR=${OSAD_REPO_DIR:-"/opt/os-ansible-deployment"}
CONFIG_PREFIX=${CONFIG_PREFIX:-openstack}

## Jenkins centric variables
PRODUCT_URL=${PRODUCT_URL:-https://github.com/stackforge/os-ansible-deployment}
PRODUCT_BRANCH=${PRODUCT_BRANCH:-master}
JENKINS_RPC_URL=${JENKINS_RPC_URL:-https://github.com/rcbops/jenkins-rpc}
JENKINS_RPC_BRANCH=${JENKINS_RPC_BRANCH:-master}
TEMPEST_SCRIPT_PARAMETERS=${TEMPEST_SCRIPT_PARAMETERS:-api}
ANSIBLE_FORCE_COLOR=${ANSIBLE_FORCE_COLOR:-1}
ANSIBLE_OPTIONS=${ANSIBLE_OPTIONS:--v}
UPGRADE=${UPGRADE:-NO}
UPGRADE_BRANCH=${UPGRADE_BRANCH:-master}
DEPLOY_MAAS=${DEPLOY_MAAS:-"yes"}
DEPLOY_HAPROXY=${DEPLOY_HAPROXY:-"no"}

env

function ssh_command {
  local command="$1"
  local infra01

  infra01="$(grep --only-matching --max-count=1 \
    '[0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+' ./playbooks/inventory/${LAB_PREFIX}-${LAB})" > /tmp/env
  echo "export ANSIBLE_FORCE_COLOR=${ANSIBLE_FORCE_COLOR}" >> script_env
  scp script_env $infra01:/tmp/env

  ssh root@$infra01 "source /tmp/env; ${command}"
}

function run_tag {
  export ANSIBLE_FORCE_COLOR
  local tag="$1"
  
  echo "Running ${tag} from multinode.yml"
  
  ansible-playbook \
    --inventory-file="playbooks/inventory/${LAB_PREFIX}-${LAB}" \
    --extra-vars="@playbooks/vars/${LAB_PREFIX}-${LAB}.yml" \
    --extra-vars="repo_dir=${REPO_DIR}" \
    --extra-vars="osad_repo_dir=${OSAD_REPO_DIR}" \
    --extra-vars="product_url=${PRODUCT_URL}" \
    --extra-vars="product_branch=${PRODUCT_BRANCH}" \
    --extra-vars="config_prefix=${CONFIG_PREFIX}" \
    --tags="${PRODUCT},${tag},${LAB_PREFIX}" \
    ${ANSIBLE_OPTIONS} \
    playbooks/multinode.yml
}

function run_script {
  local script="$1"

  echo "Running script ${1} from ${REPO_DIR}/scripts."
  ssh_command "cd ${REPO_DIR}; bash scripts/${script}.sh"
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
  echo "export DEPLOY_HAPROXY=${DEPLOY_HAPROXY}" > script_env
  run_script $RUN_SCRIPT
}

function upgrade {
  run_tag upgrade
  run_script $RUN_UPGRADE
}

function test {
  echo "export TEMPEST_SCRIPT_PARAMETERS=${TEMPEST_SCRIPT_PARAMETERS}" > script_env
  
  # Due to rpc-openstack having osad as a git submodule
  # when we run the tests for deploying from rpc-openstack
  # we have to change the DIR that we start from
  REPO_DIR=$OSAD_REPO_DIR
  run_script $TEST_SCRIPT
}

function rekick {
  run_tag rekick
}

function cleanup {
  run_tag cleanup
}

function main {
  local status_code

  # Set vars determinate on what product we are testing
  if [[ "${PRODUCT}" = "rpc" ]]; then
    echo "Inside RPC"
    RUN_SCRIPT=deploy
    UPGRADE_SCRIPT=upgrade
    TEST_SCRIPT=run-tempest
    OSAD_REPO_DIR="${REPO_DIR}/os-ansible-deployment"
    if [[ "${LAB_PREFIX}" = "nightly" ]]; then
      DEPLOY_MAAS="no"
      DEPLOY_HAPROXY="yes"
    fi
  else
    echo "Inside OSAD"
    RUN_SCRIPT=run-playbooks
    UPGRADE_SCRIPT=run-upgradeupgrade
    TEST_SCRIPT=run-tempest
    OSAD_REPO_DIR="/opt/os-ansible-deployment"
  fi

  status_code=0
  for tag in ${TAGS}
  do
    $tag || { rc=1; break; }
  done

  exit $status_code
}

main "$@"
