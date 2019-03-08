#!/bin/bash

########  Public functions #####################

#Usage: dns_pythondnsd_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
#Return 0 on success
dns_pythondnsd_add() {
  fulldomain=$1
  txtvalue=$2
  _info "Using Python DNS script"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  echo $txtvalue >> /opt/acme-challenge/records/$fulldomain

  return 0
}

#Usage: fulldomain txtvalue
#Remove the txt record after validation.
dns_pythondnsd_rm() {
  fulldomain=$1
  txtvalue=$2
  _info "Using Python DNS script"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  /bin/rm -f /opt/acme-challenge/records/$fulldomain

  return 0
}
