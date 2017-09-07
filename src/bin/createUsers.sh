#!/bin/sh

source /opt/zimbra/bin/zmshutil || exit 1
zmsetvars \
	zimbra_home \
	zimbra_server_hostname

DOMAIN=$1

if [ x$DOMAIN = "x" ]; then
	echo "Usage: $0 <domain>"
	echo ""
	exit 1
fi

zmprov ca user1@${DOMAIN} test123

zmprov ca user2@${DOMAIN} test123

