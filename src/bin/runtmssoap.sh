#!/bin/bash
SOAP_EXT_DIR=/opt/qa/soapvalidator/bin/jars
SOAP_ROOT=/opt/qa/soapvalidator
java -client -Xms512m -Xmx512m -Djava.ext.dirs=${SOAP_EXT_DIR}:/Library/Java/Home/lib/ext \
    -Djava.library.path=/usr/local/staf/lib \
    -classpath /usr/local/staf/lib/JSTAF.jar:/opt/qa/soapvalidator/bin/zimbraxml.jar \
    com.zimbra.qa.staf.StafTestMain \
    -e dev_internal -z ${SOAP_ROOT} -p ${SOAP_ROOT}/conf/global.properties -l ${SOAP_ROOT}/conf/log4jSTAF.properties "$@"
