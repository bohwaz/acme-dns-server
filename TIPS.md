For creating and renewing my Let's Encrypt certificates, I'm not using certbot, as I find that it is too complicated and often fails in unexpected ways.

Instead I'm using a lightweight alternative, programmed in bash, called [dehydrated](https://github.com/dehydrated-io/dehydrated). It is easy to understand and debug and works flawlessly. It's also packaged in Debian.

# HTTP challenge redirect

If you just want certificates for `example.org` and `my.example.org` it's quite easy, you just set up dehydrated using its default config, and it verifies that you own the subdomain by doing a HTTP request to a specific URL inside the `/.well-known/acme-challenge/` directory. Easy.

One thing that I find useful with my Apache server is to also install the `dehydrated-apache2` package that will automatically set an alias for `/.well-known/acme-challenge/` URL for all virtual hosts.

But because I'm redirecting all my HTTP-only virtual hosts to HTTPS, the challenge response will fail if I just set up a basic RewriteRule or Redirect. So one thing to think about is to exclude this path from the redirect. This can be done easily in the regexp:

```
<VirtualHost *:80>
  ServerName example.org
  RedirectMatch 301 ^(/(?!\.well-known/acme-challenge/).*) https://example.org$1
</VirtualHost>
```

# Using DNS challenge

Now if you want a certificate for `*.example.org` you have to use a DNS challenge. This means that when Let's Encrypt will verify that you own this domain name, it will send a DNS request for a `TXT` record on `_acme-challenge.example.org`. So you need to create this record, containing a specific random value.

DNS servers can be quite slow to update records, and complex to interact with. I first tried with PowerDNS and its HTTP API, but it often failed, it was cumbersome.

I found out that the best solution for handling DNS challenges for Let's Encrypt is by using a separate DNS server that will only handle the DNS requests for Let's Encrypt.

You don't need to get heavyweight solutions like PowerDNS or Bind, instead you can rely on a lightweight DNS server that will only reply to TXT records.

## Python ACME DNS server

I'm using the [Python ACME DNS server developed by pawitp](https://github.com/pawitp/acme-dns-server/tree/master). It is packaged as a systemd service by [hanzi](https://github.com/hanzi/acme-dns-server). I forked it to provide a dehydrated hook and more scripts that make your life easier: [https://github.com/bohwaz/acme-dns-server](https://github.com/bohwaz/acme-dns-server).

Just follow the instructions from the README and you are done.

This server runs on a public IP address, and you just have to create a text file in a specific directory to answer a challenge:

```
echo '"RANDOM_CHALLENGE"' > /opt/acme-challenge/records/example.org
```

Then the server will be able to return a TXT reply:

```
$ dig +short TXT _acme-challenge.example.org
"RANDOM_CHALLENGE"
```

## Setting up the DNS records to your ACME DNS server

Of course you first need to create a DNS record for `_acme-challenge.example.org` that points to your ACME DNS server. You have to use a `CNAME` or `NS` record type. The pointed server record must have a `A` or `AAAA` record itself:

```
_acme-challenge.example.org IN NS acme.example.org.
acme.example.org IN A 1.2.3.4
```

If you have another domain name, you only have to create the NS record:

```
_acme-challenge.otherexample.net IN NS acme.example.org.
```

## Configuration of Dehydrated

Dehydrated just requires to use [a custom hook script](https://github.com/bohwaz/acme-dns-server/blob/master/dehydrated_hook.sh) and to change its configuration in `/etc/dehydrated/config`:

```
CHALLENGETYPE="dns-01"
HOOK=dehydrated_dns_hook.sh

# Chain challenges: important for the provided hook (and faster)
HOOK_CHAIN=yes
```

But changing the configuration like this means that all domains will now use the DNS challenge. This can be cumbersome.

## Mixing DNS and HTTP challenges

If you want to be able to have both domains with HTTP and DNS challenges, you will have to create a new config for Dehydrated like this:

```
#!/bin/bash

. /etc/dehydrated/config

CHALLENGETYPE="dns-01"
HOOK=dehydrated_dns_hook.sh

# Chain challenges: important for the provided hook (and faster)
HOOK_CHAIN=yes

DOMAINS_TXT=/etc/dehydrated/dns_domains.txt
```

Then instead of running `dehydrated -c`, you can run:

```
dehydrated -c
dehydrated -c -f /etc/dehydrated/dns_config
```

The first command will handle HTTP challenges for domains listed in `/etc/dehydrated/domains.txt`, and the second command will handle the DNS challenges for domains listed in `/etc/dehydrated/dns_domains.txt`. Easy!

## Making sure your software is using the last certificate

I then created a short script that will renew certificates and reload the certificates for Apache, Exim and Dovecot:

```
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
```
