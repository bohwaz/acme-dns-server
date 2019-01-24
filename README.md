# Simple DNS server for acme.sh

This is a fork of [pawitp/acme-dns-server](https://github.com/pawitp/acme-dns-server). Please see that repository's README for further information.

My goal was to have a simple standalone solution for issuing wildcard certificates.

## Set up

1. Copy `dns_pythondnsd.sh` to `~/.acme.sh/`.

2. Make sure what `_acme-challenge.example.org` has a NS record pointing to this server.

Then:

```bash
# This only needs to be done once.
export PYTHONDNSD_Path=/path/to/this/repo # without trailing slash!
export PYTHONDNSD_Host=0.0.0.0 # This probably won't work due to systemd-resolve,
                               # so this needs to be the public IP address.

acme.sh --dns dns_pythondnsd -d example.org
```
