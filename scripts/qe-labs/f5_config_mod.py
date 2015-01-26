#!/usr/bin/env python

import argh
import os.path
from subprocess import check_call, CalledProcessError


def run_cmd(command):
    """ Runs a command and returns an array of its results

    :param command: String of a command to run within a shell
    :returns: Dictionary with keys relating to the execution's success
    """
    try:
        ret = check_call(command, shell=True)
        return {'success': True, 'return': ret, 'exception': None}
    except CalledProcessError, cpe:
        return {'success': False,
                'return': None,
                'exception': cpe,
                'command': command}

def main(config=None, mod=None):
    if config is None or not os.path.isfile(config):
        print "Configuration file required"
        sys.exit(0)
    if mod is None:
        print "IP mod required"
        sys.exit(0)
    command = ("cat " + config + \
                   " | sed 's/\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)/\\1%" + \
                   mod + "/'  | sed 's/\(0\.0\.0\.0\)/\\1%" + mod + "/'")
    run_cmd(command)

argh.dispatch_command(main)
