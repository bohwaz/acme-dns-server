# Simple DNS server for acme.sh

This is a fork of [pawitp/acme-dns-server](https://github.com/pawitp/acme-dns-server). Please see that repository's README for further information.

My goal was to have a simple standalone solution for issuing wildcard certificates.

## Set up

1. Execute `setup.sh` (current user needs to be root or able to use sudo).

2. Adjust owner/chmod for `/opt/acme-challenge/records`.

3. Check whether settings in `/etc/default/acme-dns-server` are correct.
