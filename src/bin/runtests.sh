#!/bin/sh -x
#
# This script runs the nightly tests.  
# 
# Usage: runtest.sh <builddir>
#   where <builddir> is the base of directory that the build is going into.
#   for example, /home/build/builds/20041028100132
#

# usage check
if [ $# -ne 2 ]
then 
	echo "Usage: $0 <builddir> <admin_password>"
	echo "    where <builddir> is the directory where the build resides"
	echo "    where <admin_password> is the system administrator password"
	exit 1
fi

RUN_ROOT=`dirname $0`
RUN_ROOT=`(cd "${RUN_ROOT}"; pwd)`

# Start the statistics script
#/bin/sh -x ${RUN_ROOT}/runstats.sh /opt/zimbra $1/ZimbraQA /qaweb

# First, configure the server with the test domains, accounts, etc.
#
#/usr/bin/perl $1/ZimbraQA/src/bin/ServerSetup/QAsetup /opt/zimbra $1/ZimbraQA <$1/ZimbraQA/src/bin/ServerSetup/SOAPData 

# Next, run the SOAP harness
#
#/bin/sh -x ${RUN_ROOT}/runsoap.sh /opt/zimbra $1/ZimbraQA /qaweb

# Next, run the QuickTestPro (QTP) GUI harness
#
/bin/sh -x ${RUN_ROOT}/runqtp.sh $1 $2

# Finally, run any report tools, but only for the full suite of SOAP tests
#/usr/bin/perl ${RUN_ROOT}/runreports.sh /opt/zimbra $1/ZimbraQA $1/ZimbraQA/results/logs_all


# Done!
#
exit 0
