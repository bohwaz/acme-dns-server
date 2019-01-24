#!/bin/bash

########  Public functions #####################

#Usage: dns_pythondnsd_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
#Return 0 on success
dns_pythondnsd_add() {
  PYTHONDNSD_Path="${PYTHONDNSD_Path:-$(_readaccountconf_mutable PYTHONDNSD_Path)}"
  PYTHONDNSD_Host="${PYTHONDNSD_Host:-$(_readaccountconf_mutable PYTHONDNSD_Host)}"

  if [ -z $PYTHONDNSD_Path ]
  then
    PYTHONDNSD_Path=""
    _err "You must specify PYTHONDNSD_Path."
    return 1
  fi

  if [ -z $PYTHONDNSD_Host ]
  then
    PYTHONDNSD_Host=""
    _err "You must specify PYTHONDNSD_Host."
    return 1
  fi

  fulldomain=$1
  txtvalue=$2
  _info "Using Python DNS script"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  if [ ! -f $PYTHONDNSD_Path/acme-dns-server.lock ]
  then
    echo "locked" > $PYTHONDNSD_Path/acme-dns-server.lock
    /usr/bin/sudo /usr/bin/python3 $PYTHONDNSD_Path/acme-dns-server.py $PYTHONDNSD_Host 53 $PYTHONDNSD_Path/records/ &
  fi

  echo $txtvalue >> $PYTHONDNSD_Path/records/$fulldomain

  _saveaccountconf_mutable PYTHONDNSD_Path  "$PYTHONDNSD_Path"
  _saveaccountconf_mutable PYTHONDNSD_Host  "$PYTHONDNSD_Host"

  return 0
}

#Usage: fulldomain txtvalue
#Remove the txt record after validation.
dns_pythondnsd_rm() {
  PYTHONDNSDN_Path="${PYTHONDNSD_Path:-$(_readaccountconf_mutable PYTHONDNSD_Path)}"

  fulldomain=$1
  txtvalue=$2
  _info "Using Python DNS script"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  /bin/rm -f $PYTHONDNSD_Path/records/$fulldomain
  if [ -f $PYTHONDNSD_Path/acme-dns-server.lock ]
  then
    /bin/rm -f $PYTHONDNSD_Path/acme-dns-server.lock
    /usr/bin/sudo /bin/kill `/bin/cat $PYTHONDNSD_Path/acme-dns-server.pid`
    /bin/rm -f $PYTHONDNSD_Path/acme-dns-server.pid
  fi

  return 0
}
