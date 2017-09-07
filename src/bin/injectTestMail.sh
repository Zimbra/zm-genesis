#!/bin/sh

source /opt/zimbra/bin/zmshutil || exit 1
zmsetvars \
	zimbra_home \
	zimbra_server_hostname


USER=$1

if [ x$USER = "x" ]; then
	echo "Usage: $0 <user@domain>"
	echo ""
	exit 1
fi


zmlmtpinject -a localhost -p 7025 -r ${USER} -s ho@${zimbra_server_hostname} -d ${zimbra_home}/qa/TestMailRaw

