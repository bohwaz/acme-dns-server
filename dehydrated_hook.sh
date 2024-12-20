#!/usr/bin/env bash

set -e
set -u
set -o pipefail

fatalerror() { echo "Error: $*" >&2; exit 1; }

. /etc/default/acme-dns-server

[[ -n "${ACME_DNS_DIRECTORY:-}" ]] || fatalerror "ACME_DNS_DIRECTORY setting is required."

deploy_challenge() {
	local DOMAIN="${1}{ACME_DNS_ALIAS:-}"

	echo " + Creating DNS TXT challenge for ${DOMAIN}"
	TARGET="$ACME_DNS_DIRECTORY/_acme-challenge.${DOMAIN}"
	echo -n > ${TARGET}
	chmod og+r ${TARGET}

	# Manage multiple token values
	while (( "$#" >= 3 )); do
		shift # Skip domain
		shift # Skip TOKEN_FILENAME
		local TOKEN_VALUE="${1}"; shift

		echo $TOKEN_VALUE >> ${TARGET}
	done

	echo "   Checking TXT record..."
	TEST=$(dig +short TXT _acme-challenge.${DOMAIN})

	[[ "$TEST" != '"Invalid request"' ]] || fatalerror "dig failed: ${TEST}"
	echo "$TEST"
}

exit_hook() {
	rm -f $ACME_DNS_DIRECTORY/*
}

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(deploy_challenge|exit_hook)$ ]]; then
	"$HANDLER" "$@"
fi

