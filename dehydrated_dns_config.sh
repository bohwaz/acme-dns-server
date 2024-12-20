#!/bin/bash

. /etc/dehydrated/config

CHALLENGETYPE="dns-01"
HOOK=dehydrated_dns_hook.sh

# Chain challenges: important for the provided hook (and faster)
HOOK_CHAIN=yes

DOMAINS_TXT=/etc/dehydrated/dns_domains.txt
