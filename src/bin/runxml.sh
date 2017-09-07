#!/bin/sh
#

#
# Usage: runxml.sh <zimbra install dir> <Zimbra QA dir> <Soap XML File>
#   where:
#		<zimbra install dir> is the zimbra install dir (i.e. /opt/zimbra)
#		<Zimbra QA dir> is the location of the QA scripts (i.e. /p4/main/ZimbraQA)
#		<Soap XML File> is the XML filename to execute
#
#
#   for example:
#
#		runsoap.sh /opt/zimbra /home/build/builds/20050119/ZimbraQA message_add.xml
#
#


#
# usage check
COMMAND_LINE="$0 $*"
if [ $# -ne 3 ]
then
	echo "You typed: $COMMAND_LINE"
	echo "Usage: $0 <zimbra home> <ZimbraQA dir> <SOAP XML File>"
	echo "	<zimbra home>: the zimbra install dir (i.e. /opt/zimbra)"
	echo "	<ZimbraQa home>: the location of the QA scripts (i.e. /p4/main/ZimbraQA)"
	echo "	<SOAP XML File>: a soap xml file name to execute"
	exit 1
fi


# Store the command line arguments
#
INSTALL_ROOT=$1
QA_ROOT=$2
QA_XML_FILE=$3


# ZimbraQA directory
QA_XML_ROOT=$QA_ROOT/data
QA_GLOBAL_CONF=$QA_ROOT/conf/global.properties
QA_RESULTS=$QA_ROOT/results
QA_TEMP=$QA_RESULTS/temp



# /opb/zimbra folders
INSTALL_LIB=$INSTALL_ROOT/lib/jars

# Java Settings
#
ZIMBRA_CLASS_PATH="$QA_ROOT/build/classes:$INSTALL_LIB/zimbracommon.jar:$INSTALL_LIB/zimbrastore.jar:$INSTALL_LIB/commons-cli-1.2.jar:$INSTALL_LIB/dom4j-1.5.jar:$INSTALL_LIB/log4j-1.2.8.jar:$INSTALL_LIB/commons-httpclient-2.0.1.jar:$INSTALL_LIB/commons-logging.jar:$INSTALL_LIB/jaxen-1.1-beta-3.jar:$INSTALL_LIB/ical4j-0.9.16-patched.jar:$INSTALL_LIB/javamail-1.4.3.jar:$INSTALL_LIB/activation.jar"
LOG4J_CONF_FILE="$QA_ROOT/conf/log4j.properties"
GLOBAL_CONF_FILE="$QA_ROOT/conf/global.properties"

#
JAVA_HOME=$INSTALL_ROOT/java
JAVA_COM=${JAVA_HOME}/bin/java
JAVA_ARGS="-cp $ZIMBRA_CLASS_PATH com.zimbra.qa.soap.SoapTestCore -l $LOG4J_CONF_FILE -d -p $GLOBAL_CONF_FILE"

TODAY=`date '+%m-%d-%y'`
TIME_NOW=`date '+%H:%M:%S'`
HOSTNAME=`hostname -s`
FQDN_HOSTNAME=`hostname`
USER_ID=`id -u -n`


PATH=$JAVA_HOME/bin:$PATH
export PATH


LOG_MSG()
{
        MSG="$*"

        echo "$MSG"

}


LOG_ERR()
{
        ERR="$*"

        echo "*** ERROR: $ERR"

}

FATAL_ERR()
{

	LOG_ERR "$*"

	# Send an email to notify of the failure

	# exit
	exit 1

}


CHECK_BUILD()
{

	# For now, the rpm -qi really doesn't lead back to the build source
	# So, simply check that the installed and QA files are present
	
	if [ ! -d $INSTALL_ROOT ]; then
		FATAL_ERR "INSTALL_ROOT($INSTALL_ROOT) does not exist!"
	fi

	if [ ! -d $QA_ROOT ]; then
		FATAL_ERR "QA_ROOT($QA_ROOT) does not exist!"
	fi


}





EXECUTE_SOAP_XML()
{
	DIR=$1
	FILE=$2

	QA_LOGS="logs"

	# Initialize the counters
	COUNT_TOTAL=0
	COUNT_UNKNOWN=0
	COUNT_PASS=0
	COUNT_FAIL=0
	COUNT_SCRIPT_FAIL=0

	
	

	# Find all the XML files.
	#
	XML_FILELIST=$QA_TEMP/xml_filelist
	(cd $DIR; find . -name "$FILE" >$XML_FILELIST 2>/dev/null)


	# Run the tests
	while read TC_FILE; do

		BASE_NAME=`basename $TC_FILE .xml`
		DIR_NAME=`dirname $TC_FILE`
		
		echo -e "\nProcessing ${BASE_NAME}.xml ..."

		# Make sure the output director exists
		#
		mkdir -p $QA_RESULTS/$QA_LOGS/$DIR_NAME

		echo "Output written to $QA_RESULTS/$QA_LOGS/$DIR_NAME ..."


		# Need to cd to the data folder, so that TestMailRaw
		# is in the folder (TestMailRaw is used to upload
		#emails and files)
		(cd $DIR/..; $JAVA_COM $JAVA_ARGS $TC_TYPE -f soapvalidator/$TC_FILE >$QA_RESULTS/$QA_LOGS/$DIR_NAME/$BASE_NAME.out 2>$QA_RESULTS/$QA_LOGS/$DIR_NAME/$BASE_NAME.err)


		# Extract the individual test case counts
		#
		RESULTS_INFO_LINE=`grep "script_parsable" $QA_RESULTS/$QA_LOGS/$DIR_NAME/$BASE_NAME.out`
		if [ "$RESULTS_INFO_LINE" ]; then

			TMP_PASS=`echo $RESULTS_INFO_LINE | awk '{ print $2 }'`
			TMP_FAIL=`echo $RESULTS_INFO_LINE | awk '{ print $3 }'`


			COUNT_TOTAL=`expr $COUNT_TOTAL + $TMP_PASS`
			COUNT_TOTAL=`expr $COUNT_TOTAL + $TMP_FAIL`
			COUNT_PASS=`expr $COUNT_PASS + $TMP_PASS`
			COUNT_FAIL=`expr $COUNT_FAIL + $TMP_FAIL`

			echo "Results: Executed(`expr $TMP_PASS + $TMP_FAIL`) PASS($TMP_PASS) FAIL($TMP_FAIL)"

		else
		
			# If there is a java error, the parse string will not be written
			COUNT_SCRIPT_FAIL=`expr $COUNT_SCRIPT_FAIL + 1`
			echo "Results: Script returned code 1.  Look in .err log"
			
		fi


	done < $XML_FILELIST

	echo "Tests run:    $COUNT_TOTAL"
	echo "Tests pass:   $COUNT_PASS"
	echo "Tests fail:   $COUNT_FAIL"
	echo "Scripts fail: $COUNT_SCRIPT_FAIL"


}



# Make sure the environment, build, etc. are correct
CHECK_BUILD

mkdir -p $QA_RESULTS
mkdir -p $QA_TEMP




# Only run smoke tests
EXECUTE_SOAP_XML $QA_XML_ROOT/soapvalidator $QA_XML_FILE



# Done!
#
exit 0
