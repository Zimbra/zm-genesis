#!/bin/sh

#
# Shell script to start the load generator client side.  This can be run anywhere, but 
# needs access to the zimbra jar files and directories that include sample message
# bodies.  Arguments are:
# $1: the XML profile file that defines the characteristics of the users in the run
# $2: lowest user number to simulate
# $3: number of users to simulate (starting at $2)
# $4: domain of the simulated users
# $5: base URL for SOAP service (without /service/soap)
# $6: number of worker threads to use (maximum)
# 
# Example: to simulate users 5000-8000 against rackable, running populate.xml, with 25
# threads, run 
# "soapgen.sh populate.xml 5000 3000 rackable.zimbra.com http://rackable.zimbra.com:7070 25"
#
# The 700 MB heap size is only needed for really large simulations.  You can usually
# get by with a lot less, maybe 200 MB.
#
# The QADIR/classes bit in the classpath is to provide a simple override mechanism for
# new classes without a new build/jar file.  It need not exist.
#

QADIR="/home/qa"

JARDIR="/opt/zimbra/lib"
export JARDIR

PATH=/opt/zimbra/java/bin:${path}
export PATH

java -Xmx700m -classpath ".:${QADIR}/classes:${JARDIR}/log4j-1.2.8.jar:${JARDIR}/guava-r07.jar:${JARDIR}/commons-codec-1.2.jar:${JARDIR}/zimbrastore.jar:${JARDIR}/commons-cli-1.0.jar:${JARDIR}/commons-httpclient-2.0.1.jar:${JARDIR}/commons-logging.jar:${JARDIR}/dom4j-1.5.jar:${JARDIR}/PDFBox-0.6.5.jar:${JARDIR}/activation.jar:${JARDIR}/commons-cli-1.0.jar:${JARDIR}/commons-dbcp-1.1.jar:${JARDIR}/commons-fileupload-1.0.jar:${JARDIR}/commons-pool-1.1.jar:${JARDIR}/jaxen-1.1-beta-3.jar:${JARDIR}/jug-1.1.2.jar:${JARDIR}/javamail-1.4.3.jar:${JARDIR}/mysql-connector-java-3.0.14-production-bin.jar"  -Dlog4j.configuration=/opt/zimbra/jakarta-tomcat-5.0.28/webapps/service/WEB-INF/classes/log4j.properties  com.zimbra.qa.load.SoapGenerator -f $1 -u $2 -d $4 -n $3 -s $5 -t $6 
