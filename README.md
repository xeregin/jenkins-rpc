Description
===

Welcome to my little docker lab!

This is a simple Ansible orchestrator to kick a small cluster of Rackspace Cloud Servers. It will also provision the cluster as docker hosts for running ![Scrambler](https://github.com/Apsu/scrambler) orchestration agents. This is primarily designed to be run from Jenkins, and plumbing is provided to dynamically generate host/network metadata from environment variables passed to the build scripts. Of course the env variables can also be passed manually for easy CLI invocation.

Requirements
---

A Rackspace Cloud account is required, as well as the `pyrax` library installed locally for Ansible's `rax` module to use. Furthermore, we make use of the `host` and `interfaces` modules from ![Apsu's fork of Ansible](https://github.com/Apsu/ansible/tree/dockerlab) until Ansible upstream figures out what to do with `host` and accepts the PR for `interfaces`.

Inventory (Hosts)
---

The inventory is currently configured (via `ansible.cfg`) as a directory in the project root, `./inventory`, and contains `group_vars` and the `hosts` file. The included `hosts` file is very minimal since `hosts.yml` generates hosts dynamically, but you can specify a static inventory if you like, and not use `hosts.yml`. Either way, the structure of hosts and groups is as follows:

* Local -- Group for local_action targeting
  * Just contains "localhost" at present
* Infra -- Group for the controller nodes

These groups are then collected and divided into two other useful groups for targeting by various roles:

* Hosts -- This contains all hosts for site-wide tasks
* Cluster -- This will differentiate between controllers and compute nodes in the near future

`group_vars` set a few bits of miscellaneous info, though these are particularly important:

* group_vars/all.yml -- Configuration for images, networks, various ansible bits

Credentials
---

The ensure-hosts role expects a `rax_creds` file to exist in the base directory with the following contents:

    [rackspace_cloud]
    username = someuser
    api_key = somekey

The `group_vars/all.yml` also sets the SSH keypair name for the nodes, which must already exist. You can add one to your account via `nova keypair-add` using the nova command-line client. This will automatically add the public key to `~/.ssh/authorized_keys` on each node. Furthermore, you can supply public/private keypairs to be pushed into `~/.ssh` by placing `id_*` files into `roles/configure-hosts/files`, creating the directory if it doesn't exist.

Workflow Playbooks
---

Currently there are two main playbooks combining various functional playbooks for common workflows:

* `build.yml` is the primary playbook for kicking an entire cluster, end to end. The included `ensure.yml` will ensure the hosts exist, creating them if needed. It then runs `configure.yml`, `reboot.yml` and `provision.yml` to fully configure the cluster hosts, with a reboot for potential new kernels inbetween.
* `deploy.yml` is the same as `build.yml` but first runs `hosts.yml` to build the host inventory from environment variables.
* `destroy.yml` runs `delete.yml` but first runs `hosts.yml`, same as above.
* `redeploy.yml` just runs `destroy.yml` followed by `deploy.yml`, resulting in a complete teardown and rebuild of the cluster.

Functional Playbooks
---

The functional playbooks are `hosts.yml`, `ensure.yml`, `delete.yml`, `configure.yml`, `provision.yml` and `reboot.yml`. Each of the included plays are tagged by function and apply their tags to the roles they include for useful filtering.

As mentioned previously, `hosts.yml` provides dynamic hostname/network generation for consumption by subsequent playbooks.

Roles
---

There are several roles tailored to composable sets of functionality. Tasks in each role are also individually tagged for more granular filtering. These include:

* configure-hosts -- Basic post-install groundwork, configures networking and tests it
* delete-hosts    -- Deletes host servers
* delete-networks -- Deletes host networks
* ensure-hosts    -- Creates host servers and learns how to talk to them for other roles
* ensure-networks -- Creates host networks
* reboot-hosts    -- Reboots the cluster hosts and waits for them to be responsive again
* provision-hosts -- Main provisioning steps, installing packages, configuring and starting needed services

Jenkins
---

The two scripts designed to be run from Jenkins are `deploy.sh` and `destroy.sh`. They're fairly simple wrappers around the `deploy.yml` and `destroy.yml` playbooks, respectively. They will pushd if the repo is cloned in /opt/virtlab, and assume ansible/pyrax is in a virtualenv named `.venv` which they activate. You're welcome.

As mentioned above, there are several environment variables required whether running Dockerlab from Jenkins or not. The variables are:

* BUILD_PREFIX -- A string describing the prefix for each cluster host name
* BUILD_NUMBER -- A number describing the build to help provide unique builds with the same prefix
* BUILD_COUNT  -- A number specifying the number of nodes to build for this cluster

The pattern for host names is constructed from `$BUILD_PREFIX-$BUILD_NUMBER-node$index`, where `$index` is a number from 1 to `$BUILD_COUNT`.

Networking
---

Custom cloud networks are dealt with in the same way (and in the same playbooks) as hosts, created or deleted as required, and associated with hosts as required. Refer to the `hosts.yml` playbook and `group_vars/all.yml` for details on network specification format and default values.

Provisioning
---

Whether provided statically or generated dynamically, we will know hostnames and groups but not their IP addresses, and must discover them. This is currently implemented in the `ensure-hosts` role by building new ones (if they don't exist) with the inventory hostnames and registering the public IPv4 addresses for subsequent SSH access. You can also delete the hosts with the `delete-hosts` role; the `redeploy.yml` playbook does this before building new ones. It is not necessary to delete hosts every time as the building process is idempotent, discovering host information if they exist. Either way, `ensure-*` tags must always be run before any other playbooks when not using a static inventory.

Errata
===

Some tasks are a little terrible to figure out their current state and decide if running them caused a change or not. Please try to forgive some of the travesties you'll encounter involving abuse of failed_when, changed_when and friends.
