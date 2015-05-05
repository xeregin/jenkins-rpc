#!/usr/bin/env bash

### -------------- [ Variables ] --------------------
LAB=${LAB:-master}
TAGS=${TAGS:-rekick prepare run upgrade test}
OS_ANSIBLE_URL=${OS_ANSIBLE_URL:-git@github.com:stackforge/os-ansible-deployment.git}
OS_ANSIBLE_BRANCH=${OS_ANSIBLE_BRANCH:-master}
JENKINS_RPC_URL=${JENKINS_RPC_URL:-git@github.com:rcbops/jenkins-rpc.git}
JENKINS_RPC_BRANCH=${JENKINS_RPC_BRANCH:-master}
TEMPEST_SCRIPT_PARAMETERS=${TEMPEST_SCRIPT_PARAMETERS:-api}
ANSIBLE_FORCE_COLOR=${ANSIBLE_FORCE_COLOR:-1}
ANSIBLE_OPTIONS=${ANSIBLE_OPTIONS:--v}
UPGRADE=${UPGRADE:-YES}
UPGRADE_BRANCH=${UPGRADE_BRANCH:-master}

### -------------- [ Functions ] --------------------

env

run_playbook_tag(){
  export ANSIBLE_FORCE_COLOR
  echo "Running tag ${1} from jenkins-rpc/nightly-multinode.yml"
  ansible-playbook \
    -i inventory/nightly-${LAB}\
    -e @vars/nightly-${LAB}.yml\
    -e os_ansible_branch=${OS_ANSIBLE_BRANCH}\
    --tags $1\
    $ANSIBLE_OPTIONS\
    nightly-multinode.yml
}

run_script(){
  #Find the first node ip from the inventory
  [[ -z $infra_1_ip ]] && infra_1_ip=$(grep -o -m 1 '10.127.[0-9]\+.[0-9]\+' \
                          < inventory/nightly-$LAB)
  : >> /tmp/env
  echo "export ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR" >> script_env
  scp script_env $infra_1_ip:/tmp/env
  echo "Running script ${1} from os-ansible-deployment/scripts."
  ssh root@$infra_1_ip "source /tmp/env; cd ~/rpc_repo; bash scripts/${1}.sh"
}

run_upgrade(){
  #Find the first node ip from the inventory
  [[ -z $infra_1_ip ]] && infra_1_ip=$(grep -o -m 1 '10.127.[0-9]\+.[0-9]\+' \
                          < inventory/nightly-$LAB)
  : >> /tmp/env
  echo "export ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR" >> script_env
  scp script_env $infra_1_ip:/tmp/env
  echo "Running script ${1} from os-ansible-deployment/scripts."
  ssh root@$infra_1_ip "source /tmp/env; cd ~/rpc_repo; echo $UPGRADE | bash scripts/${1}.sh" 
}

prepare(){
  run_playbook_tag prepare
  run_script bootstrap-ansible
  run_playbook_tag configure
  run_playbook_tag reboot

  # sleep for 2 minutes to wait for ssh
  echo "Sleeping for 3 minutes to allow ssh to come up."
  sleep 180
}

run(){
  echo "export DEPLOY_TEMPEST=yes" > script_env
  run_script run-playbooks
}

test(){
  echo "export TEMPEST_SCRIPT_PARAMETERS=${TEMPEST_SCRIPT_PARAMETERS}" > script_env
  run_script run-tempest
}

upgrade(){
  # set os_ansible_branch environment varible for upgrade
  OS_ANSIBLE_BRANCH=${UPGRADE_BRANCH}

  # run jenkins-rpc upgrade tag
  run_playbook_tag upgrade

  # run os-ansible-deployment upgrade script
  run_upgrade run-upgrade
}

rekick(){
  run_playbook_tag cleanup
  run_playbook_tag rekick

  # sleep for 3 minutes to wait for ssh
  echo "Sleeping for 3 minutes to allow ssh to come up."
  sleep 180
}

### -------------- [ Main ] --------------------

# run the tags that are required until something breaks
rc=0
for tag in ${TAGS}
do
  $tag
  rc=$(( $rc + $? ))
  [[ $rc -ne 0 ]] && break
done

exit $rc
