#!/usr/bin/env python
import json
import os


def main():
    file_path = '/etc/rpc_deploy/rpc_hostnames_ips.yml'

    if not os.path.exists(file_path):
        raise IOError('Cannot locate: {0}'.format(file_path))

    with open(file_path, 'r') as fp:
        hosts = json.load(fp)
        for host in hosts:
            if 'container' in host:
                print host


if __name__ == '__main__':
    main()
