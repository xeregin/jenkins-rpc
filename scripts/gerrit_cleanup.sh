#!/bin/bash

# This script is for getting a list of open reviews with -1 code reviews and
# setting them to 0. Useful after jenkins fails a load of patches incorrectly.

# ---- Variables----
SSH_KEY=~/.ssh/id_rsa_wherenow_jenkins_openstack_ci
GERRIT_USER="wherenowjenkins"
GERRIT_HOST="review.openstack.org"
GERRIT_PORT=29418

# ---- Functions ----

# SSH to gerrit and run command
gerrit_command(){
  command="$1"
  ssh $GERRIT_USER@$GERRIT_HOST \
    -i $SSH_KEY \
    -p $GERRIT_PORT \
    "$command"
}

# Find latest patchset for each review
get_patchsets(){
python - $1 <<EOP
import click
import json

@click.command()
@click.argument('filename')
def get_patchsets(filename):
    """ Get latest patchset from a gerrit json query"""
    with open(filename) as f:
        for line in f.readlines():
            review = json.loads(line)

            # skip the stats object at the end of the gerrit query stream
            if review.get('type') == 'stats':
                continue

            num_patchsets = len(review['patchSets'])
            print '%(number)s,%(patchset)s' % {'number': review['number'],
                                             'patchset': num_patchsets}
if __name__ == '__main__':
  get_patchsets()
EOP
}

# 1) Query jenkins and dump the stream of json objects to data.json
gerrit_command \
  'gerrit query --format=json --patch-sets status: open label:Code-Review=-1,user='$GERRIT_USER \
  > data.json

# 2) Issue gerrit ssh command to vote code review 0 for each patchset
get_patchsets data.json |while read patchset
  do gerrit_command \
    'gerrit review '$patchset' --code-review 0'
    echo $patchset
  done


