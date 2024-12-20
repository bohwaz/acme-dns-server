#!/bin/bash

# Change here to put the FQDN used by your mail server
MAIL_DOMAIN="mail.example.org"

# HTTP challenge (domains.txt)
dehydrated -c -g

# DNS challenge (dns_domains.txt)
dehydrated -c -g -f dehydrated_dns_config.sh

# Remove old certificates
dehydrated -gc

CHANGED=$(find /var/lib/dehydrated/certs/ -mtime -1 -type f)

# Reload Apache
[[ -n ${CHANGED} ]] && sudo apachectl configtest && sudo apachectl graceful

# Find out if certificate for mail domain has changed
CHANGED=$(find /var/lib/dehydrated/certs/${MAIL_DOMAIN} -mtime -1 -type f)

# Reload Exim
[[ -n ${CHANGED} ]] && sudo service exim4 reload

# Reload dovecot
[[ -n ${CHANGED} ]] && sudo service dovecot reload
