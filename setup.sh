#!/bin/bash

DIR=`dirname "$0"`
REALDIR=`realpath $DIR`

sudo cp acme-dns-server.py /usr/bin/acme-dns-server.py
sudo chown root:root /usr/bin/acme-dns-server.py
sudo chmod 0755 /usr/bin/acme-dns-server.py

sudo mkdir -p /opt/acme-challenge/records

sudo cp acme-dns-server.config /etc/default/acme-dns-server
sudo cp acme-dns-server.service /etc/systemd/system/acme-dns-server.service
sudo chown root:root /etc/systemd/system/acme-dns-server.service /etc/default/acme-dns-server
sudo chmod 0644 /etc/systemd/system/acme-dns-server.service /etc/default/acme-dns-server

sudo systemctl daemon-reload
sudo systemctl enable acme-dns-server.service
sudo systemctl start acme-dns-server.service

if [ -d "~/.acme.sh/" ]; then
    cp dns_pythondnsd.sh ~/.acme.sh/
fi
