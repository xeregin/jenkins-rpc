#!/usr/bin/env python
import argh
import netaddr


def main(cidr, host):
    subnet = netaddr.IPNetwork(cidr)
    ip_address = netaddr.IPAddress(host)

    prefix = '.'.join(map(str, subnet.network.words[0:3]))
    suffix = ip_address.words[-1]
    print '%s.%s' % (prefix, suffix)


argh.dispatch_command(main)
