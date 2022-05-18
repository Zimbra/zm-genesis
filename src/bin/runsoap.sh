#!/bin/sh -x
#

#
# New version of runtests that doesn't use STAF/STAX
#
# Usage: runsoap.sh <zimbra install dir> <Zimbra QA dir> <qa web>
#   where:
#		<zimbra install dir> is the zimbra install dir (i.e. /opt/zimbra)
#		<Zimbra QA dir> is the location of the QA scripts (i.e. /p4/main/ZimbraQA)
#		<Zimbra QA dir> is the location of the QA scripts (i.e. /space/sambashare/qaweb)
#   for example:
#		runsoap.sh /opt/zimbra /home/build/builds/20050119/ZimbraQA
#		runsoap.sh c:/opt/zimbra c:/p4/ZimbraQA Z:/qaweb
#
#


#
# usage check
COMMAND_LINE="$0 $*"
if [ $# -ne 2 -a $# -ne 3 ]
then
	echo "You typed: $COMMAND_LINE"
	echo "Usage: $0 <zimbra home> <ZimbraQA dir> [ <qaweb path> ]"
	echo "	<zimbra home>: the zimbra install dir (i.e. /opt/zimbra)"
	echo "	<qa home>: the location of the QA scripts (i.e. /p4/main/ZimbraQA)"
	echo "	<qa home>: the path of the QA webpage files (i.e. /space/sambashare/qaweb) (optional)"
	exit 1
fi


# Store the command line arguments
#
INSTALL_ROOT=$1
QA_ROOT=$2
if [ $# -eq 3 ]; then
	QAWEB_ROOT=$3
else
	# The default is /space/sambashare/qaweb
	QAWEB_ROOT=/space/sambashare/qaweb
fi


# Build ARCH ... RHEL4, FC3, etc.
# Build Branch ... main, Armstrong, etc.
# Build ID ... 20050912140101_NETWORK
# QA_ROOT normally looks like /home/build/builds/RHEL4/main/20050912140101_NETWORK/ZimbraQA/
#
BUILD_ARCH=`echo $QA_ROOT | sed s#/home/build/builds/## | sed s#/.*##`
BUILD_BRANCH=`echo $QA_ROOT | sed "s#.*$BUILD_ARCH/##" | sed s#/.*##`
BUILD_ID=`echo $QA_ROOT | sed "s#.*$BUILD_BRANCH/##" | sed s#/.*##`


# ZimbraQA directory
QA_XML_ROOT=$QA_ROOT/data
QA_GLOBAL_CONF=$QA_ROOT/conf/global.properties
QA_RESULTS=$QA_ROOT/results
QA_EMAILS=$QA_RESULTS/emails
QA_TEMP=$QA_RESULTS/temp

mkdir -p $QA_RESULTS
mkdir -p $QA_EMAILS
mkdir -p $QA_TEMP


# QA Website Information
QAWEB_RESULTS_DIR=$QAWEB_ROOT/TestResults
QAWEB_RESULTS_FILE=$QAWEB_RESULTS_DIR/data/smoke_test_results.txt
QAWEB_RRD_SCRIPT=$QAWEB_RESULTS_DIR/update_results_db.perl


# /opb/zimbra folders
INSTALL_LIB=$INSTALL_ROOT/lib/jars

# Java Settings
#
ZIMBRA_CLASS_PATH="$QA_ROOT/build/classes:$INSTALL_LIB/zimbracommon.jar:$INSTALL_LIB/zimbrastore.jar:$INSTALL_LIB/commons-cli-1.2.jar:$INSTALL_LIB/dom4j-1.5.jar:$INSTALL_LIB/log4j-core-2.17.1.jar:$INSTALL_LIB/log4j-api-2.17.1.jar:$INSTALL_LIB/commons-httpclient-3.0.jar:$INSTALL_LIB/commons-logging.jar:$INSTALL_LIB/jaxen-1.1-beta-3.jar:$INSTALL_LIB/ical4j-0.9.16-patched.jar:$INSTALL_LIB/javamail-1.4.3.jar:$INSTALL_LIB/activation.jar:$INSTALL_LIB/commons-codec-1.3.jar"
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

# This file is used to determine whether to send the 'failure' email out
# Only send one failure email per day
#
EMAIL_FLAG_FILE=/tmp/${USER_ID}_build_email
touch $EMAIL_FLAG_FILE

# This file is used to determine whether to run the full suite of tests
# Only run the full suite once per day
#
FULL_FLAG_FILE=/tmp/${USER_ID}_build_fullsuite
touch $FULL_FLAG_FILE


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

        echo "ERROR ***: $ERR"

}

FATAL_ERR()
{

	LOG_ERR "$*"

	# Send an email to notify of the failure

	# exit
	exit 1

}

LOG_TEST_ENVIRONMENT()
{

        ENV_LOG=$QA_ROOT/results/test_env_$TIME_NOW.txt

        LOG_MSG "Logging the test environment ..."


        # Just in case this directory doesnt exist yet
        #
        mkdir -p $QA_ROOT/results

        echo "Test Evironment Log Start ..." >> $ENV_LOG
        date >> $ENV_LOG

        echo "Command: $COMMAND_LINE" >> $ENV_LOG

        /bin/env >> $ENV_LOG

        echo "Test Evironment Log Finish ..." >> $ENV_LOG

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


CONFIGURE_ZIMBRA_TCS()
{

	# we need to re-write the hostname in the global.properties
	# this is because the domain of the nightly test
	# is build.zimbra.com instead of zimbra.com (default)
	#
	sed s/@zimbra.com/@$FQDN_HOSTNAME/g $QA_GLOBAL_CONF > $QA_TEMP/global.properties.tmp
	mv -f $QA_TEMP/global.properties.tmp $QA_GLOBAL_CONF || {
		FATAL_ERR "Unable to move $QA_GLOBAL_CONF"
	}
		

	sed s/defaultdomain.name=zimbra.com/defaultdomain.name=$FQDN_HOSTNAME/g $QA_GLOBAL_CONF > $QA_TEMP/global.properties.tmp
	mv -f $QA_TEMP/global.properties.tmp $QA_GLOBAL_CONF || {
		FATAL_ERR "Unable to move $QA_GLOBAL_CONF"
	}

	sed s#http://localhost#http://$FQDN_HOSTNAME#g $QA_GLOBAL_CONF > $QA_TEMP/global.properties.tmp
	mv -f $QA_TEMP/global.properties.tmp $QA_GLOBAL_CONF || {
		FATAL_ERR "Unable to move $QA_GLOBAL_CONF"
	}

	sed s#https://localhost#https://$FQDN_HOSTNAME#g $QA_GLOBAL_CONF > $QA_TEMP/global.properties.tmp
	mv -f $QA_TEMP/global.properties.tmp $QA_GLOBAL_CONF || {
		FATAL_ERR "Unable to move $QA_GLOBAL_CONF"
	}


}


GATHER_RESULTS()
{

	# collect results and info logs into some central place
	LOG_MSG "copying results over..."
	
	
	# Grab the zimbra.log and save a copy for debugging
	if [ ! -f $INSTALL_ROOT/log/zimbra.log ]; then
		LOG_MSG "Where is $INSTALL_ROOT/log/zimbra.log ?"
	else
		rm -f $QA_RESULTS/zimbra.log
		cp -f $INSTALL_ROOT/log/zimbra.log $QA_RESULTS
	fi

	# The test.log/driverlog.txt is created by the build script
	if [ ! -f $INSTALL_ROOT/logs/test.log ]; then
		LOG_MSG "Where is $INSTALL_ROOT/logs/test.log ?"
	fi
	rm -f $QA_ROOT/results/driverlog.txt
	ln -s $INSTALL_ROOT/logs/test.log $QA_ROOT/results/driverlog.txt
	

	# COUNT_UNKNOWN is most likely tests that had Java exceptions
	#
	COUNT_UNKNOWN=$COUNT_TOTAL
	COUNT_UNKNOWN=`expr $COUNT_UNKNOWN - $COUNT_PASS`
	COUNT_UNKNOWN=`expr $COUNT_UNKNOWN - $COUNT_FAIL`
	
}



CREATE_RESULTS_EMAIL_TEXT()
{

	# Watch out for whitespace in lines.  Those will cause problems
	# in interpretting the difference between the end of the headers
	# and the beginning of the message.
	#
	cat > $QA_EMAILS/results.txt << ENDOFINSERT

	Build Branch: $BUILD_BRANCH
	Build ID: $BUILD_ID
	Date: `date +%c`

	$COUNT_TOTAL	- Total Test Suites Executed
	$COUNT_PASS	- Pass
	$COUNT_FAIL	- Fail
	$COUNT_SCRIPT_FAIL - Test Script Errors
	$COUNT_UNKNOWN	- Unknown status

	Failing test suites:

ENDOFINSERT
	for i in $FAILURES; do
		echo $i >> $QA_EMAILS/results.txt
	done

	echo -e "\nPassing test suites:\n" >> $QA_EMAILS/results.txt

	for i in $SUCCESSES; do
		echo $i >> $QA_EMAILS/results.txt
	done

	echo -e "\n\n\n" >> $QA_EMAILS/results.txt
}


CREATE_RESULTS_EMAIL_HTML()
{

	# Watch out for whitespace in lines.  Those will cause problems
	# in interpretting the difference between the end of the headers
	# and the beginning of the message.
	#
	cat > $QA_EMAILS/results.html <<  ENDOFINSERT

	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
	<html>
	  <head>
	    <title>Test Output</title>
	  </head>
	
	  <body>
	  
	  
	    <h1>Summary</h1>
	    
		<b>Build Branch:</b> $BUILD_BRANCH<p>
		<b>Build ID:</b> $BUILD_ID<p>
		<b>Date:</b> `date +%c`<p>
		<p>
		<p>

	    <TABLE BORDER>
		    <TR>
		    	<TD>Total:</TD> <TD>$COUNT_TOTAL</TD>
		    </TR>
		    <TR>
		    	<TD>Pass:</TD> <TD>$COUNT_PASS</TD>
		    </TR>
		    <TR>
		    	<TD>Fail:</TD> <TD>$COUNT_FAIL</TD>
		    </TR>
		    <TR>
		    	<TD>Test Script Errors:</TD> <TD>$COUNT_SCRIPT_FAIL</TD>
		    </TR>
		    <TR>
		    	<TD>Unknown:</TD> <TD>$COUNT_UNKNOWN</TD>
		    </TR>
	    </TABLE>
	    
	    <h1>Failures</h1>
	
	The following tests failed:<p>
	
ENDOFINSERT
	
	# put together a link for each failure in the test
	for FAILURE in $FAILURES
	do
	
		cat >> $QA_EMAILS/results.html << ENDOFINSERT
		
	$FAILURE
	<a href="http://$FQDN_HOSTNAME:8000/links/$BUILD_ARCH/$BUILD_BRANCH/$BUILD_ID/ZimbraQA/results/$QA_LOGS/$FAILURE.out"> (out) </a>
	-   
	<a href="http://$FQDN_HOSTNAME:8000/links/$BUILD_ARCH/$BUILD_BRANCH/$BUILD_ID/ZimbraQA/results/$QA_LOGS/$FAILURE.err"> (err) </a>
	<br>
	
ENDOFINSERT
	
	done
	
	cat >> $QA_EMAILS/results.html <<  ENDOFINSERT
	
	    <h1>Successes</h1>
	    
	    The following tests passed:<p>
	    
ENDOFINSERT

	for i in $SUCCESSES
	do
		echo "$i<br>" >> $QA_EMAILS/results.html
	done
	
cat >> $QA_EMAILS/results.html << ENDOFINSERT
		
	</body>
	</html>
	
ENDOFINSERT
	


}

CREATE_RESULTS_EMAIL()
{

	TEST_SUITE=$1

	# Always send an e-mail to matt@zimbra.com for
	# every automation suite test run.  Eventually, a
	# e-mail list should probably be set up to receive
	# all the notifications.
	#
	EMAIL_DESTINATION="$GOOD_RESULT_EMAIL_DESTINATION"

	if [ "$FAILURES" -a "$TEST_SUITE" = "smoke" ]
	then


		# if we haven't already mailed out failure today
		if [ -z "`grep "$TODAY" ${EMAIL_FLAG_FILE}_${TEST_SUITE}`" ]; then
		
			echo "$TODAY" >> ${EMAIL_FLAG_FILE}_${TEST_SUITE}

			EMAIL_DESTINATION="$BAD_RESULT_EMAIL_DESTINATION"

		fi


	fi



	# Create the plain text version
	CREATE_RESULTS_EMAIL_TEXT
	
	# Create the HTML version
	CREATE_RESULTS_EMAIL_HTML
	
	# Combine them into an e-mail format
	LOG_MSG "building e-mail message ..."
	cat > $QA_EMAILS/msg.txt << ENDOFINSERT
Subject: Test results for $BUILD_ID - Pass=$COUNT_PASS Failed=$COUNT_FAIL
To: $EMAIL_DESTINATION
From: $USER_ID@$FQDN_HOSTNAME
Content-Type: multipart/alternative; boundary="Multipart Boundary"

ENDOFINSERT

	echo "" >> $QA_EMAILS/msg.txt
	echo "--Multipart Boundary" >> $QA_EMAILS/msg.txt
	echo "Content-Type: text/plain" >> $QA_EMAILS/msg.txt
	echo "" >> $QA_EMAILS/msg.txt
	cat $QA_EMAILS/results.txt >> $QA_EMAILS/msg.txt
	
	echo "" >> $QA_EMAILS/msg.txt
	echo "--Multipart Boundary" >> $QA_EMAILS/msg.txt
	echo "Content-Type: text/html" >> $QA_EMAILS/msg.txt
	echo "" >> $QA_EMAILS/msg.txt
	cat $QA_EMAILS/results.html >> $QA_EMAILS/msg.txt

	echo "" >> $QA_EMAILS/msg.txt
	echo "--Multipart Boundary--" >> $QA_EMAILS/msg.txt
	

	LOG_MSG "Send e-mail to $EMAIL_DESTINATION ..."
#	/usr/sbin/sendmail.sendmail $EMAIL_DESTINATION < $QA_EMAILS/msg.txt


}

CREATE_RESULTS_QA_WEBSITE()
{
	TEST_SUITE="$1"
	
	if [ -d $QAWEB_ROOT ]; then

		# Log the statistics in a plain text file
	    echo "`date "+%D %R"` $BUILD_ID $BUILD_BRANCH $TEST_SUITE $COUNT_TOTAL $COUNT_PASS $COUNT_FAIL $COUNT_SCRIPT_FAIL $COUNT_UNKNOWN" >> $QAWEB_RESULTS_FILE

		# Log the statistics to the RRD database and RRD graphs
		if [ -f $QAWEB_RRD_SCRIPT ]; then
			$QAWEB_RRD_SCRIPT $TEST_SUITE $COUNT_PASS $COUNT_FAIL 0 $COUNT_UNKNOWN
		fi

	else
		LOG_MSG "Not logging to qaweb because $QAWEB_ROOT DNE"
	fi
	
}

EXECUTE_SOAP_XML()
{
	DIR=$1
	EXTENSION=$2


	# Initialize the counters
	COUNT_TOTAL=0
	COUNT_UNKNOWN=0
	COUNT_PASS=0
	COUNT_FAIL=0
	COUNT_SCRIPT_FAIL=0

	LOG_TEST_ENVIRONMENT
	
	

	# Find all the XML files.
	#
	XML_FILELIST=$QA_TEMP/xml_filelist
	(cd $DIR; find . -name "*$EXTENSION" >$XML_FILELIST 2>/dev/null)


	# Run the tests
	while read TC_FILE; do

		BASE_NAME=`basename $TC_FILE .xml`
		DIR_NAME=`dirname $TC_FILE`
		
		echo "Processing $TC_FILE ($COUNT_TOTAL, $COUNT_PASS, $COUNT_FAIL) ..."

		# Make sure the output director exists
		#
		mkdir -p $QA_RESULTS/$QA_LOGS/$DIR_NAME


#		echo "(cd $DIR; $JAVA_COM $JAVA_ARGS -f $TC_FILE >$QA_RESULTS/$QA_LOGS/$DIR_NAME/$BASE_NAME.out 2>$QA_RESULTS/$QA_LOGS/$DIR_NAME/$BASE_NAME.err; rm -f properties.txt)"
		# Need to cd to the data folder, so that TestMailRaw
		# is in the folder (TestMailRaw is used to upload
		#emails and files)
		(cd $DIR/..; $JAVA_COM $JAVA_ARGS $TC_TYPE -f soapvalidator/$TC_FILE >$QA_RESULTS/$QA_LOGS/$DIR_NAME/$BASE_NAME.out 2>$QA_RESULTS/$QA_LOGS/$DIR_NAME/$BASE_NAME.err; rm -f properties.txt)

		# Keep track of the files that passed
		if [ $? -eq 0 ]; then
			SUCCESSES="$SUCCESSES $DIR_NAME/$BASE_NAME"
		else
			FAILURES="$FAILURES $DIR_NAME/$BASE_NAME"
		fi

		# Extract the individual test case counts
		#
		RESULTS_INFO_LINE=`grep "script_parsable" $QA_RESULTS/$QA_LOGS/$DIR_NAME/$BASE_NAME.out`
		if [ "$RESULTS_INFO_LINE" ]; then

			echo "$RESULTS_INFO_LINE"
			TMP_PASS=`echo $RESULTS_INFO_LINE | awk '{ print $2 }'`
			TMP_FAIL=`echo $RESULTS_INFO_LINE | awk '{ print $3 }'`


			COUNT_TOTAL=`expr $COUNT_TOTAL + $TMP_PASS`
			COUNT_TOTAL=`expr $COUNT_TOTAL + $TMP_FAIL`
			COUNT_PASS=`expr $COUNT_PASS + $TMP_PASS`
			COUNT_FAIL=`expr $COUNT_FAIL + $TMP_FAIL`

		else
		
			# If there is a java error, the parse string will not be written
			COUNT_SCRIPT_FAIL=`expr $COUNT_SCRIPT_FAIL + 1`
			
		fi


	done < $XML_FILELIST


}



# Make sure the environment, build, etc. are correct
CHECK_BUILD


# Modify the global.properties file to match the system under test
CONFIGURE_ZIMBRA_TCS


# Email information
# This is the "To:" field on the results e-mail that is sent a automatically.
# Set it to engineering for live deployments, or
# set it to your e-mail for debugging
#
BAD_RESULT_EMAIL_DESTINATION="matt@zimbra.com"
BAD_RESULT_EMAIL_DESTINATION="engineering@zimbra.com qa-group@zimbra.com zimbra@persistent.co.in"
BAD_RESULT_EMAIL_DESTINATION="engineering@zimbra.com qa-group@zimbra.com"
GOOD_RESULT_EMAIL_DESTINATION="matt@zimbra.com"
GOOD_RESULT_EMAIL_DESTINATION="qa-group@zimbra.com zimbra@persistent.co.in"
GOOD_RESULT_EMAIL_DESTINATION="qa-group@zimbra.com"

# Only run smoke tests
TC_TYPE="-t smoke"
QA_LOGS="logs_smoke"
EXECUTE_SOAP_XML $QA_XML_ROOT/soapvalidator .xml

# The smoke suite are the default results (i.e. logs directory)
ln -s $QA_RESULTS/$QA_LOGS $QA_RESULTS/logs

# Parse the results
GATHER_RESULTS
CREATE_RESULTS_QA_WEBSITE SOAP_smoke
CREATE_RESULTS_EMAIL smoke



# Now, rerun all the tests (only once per day, though)
if [ `grep "$TODAY" $FULL_FLAG_FILE` ]; then

	LOG_MSG "The full suite has already been run today"
	
else

		
	echo "$TODAY" >> $FULL_FLAG_FILE

	
	# Email information
	# This is the "To:" field on the results e-mail that is sent a automatically.
	# Set it to engineering for live deployments, or
	# set it to your e-mail for debugging
	#
	BAD_RESULT_EMAIL_DESTINATION="qa-group@zimbra.com zimbra@persistent.co.in"
	GOOD_RESULT_EMAIL_DESTINATION="qa-group@zimbra.com zimbra@persistent.co.in"
	BAD_RESULT_EMAIL_DESTINATION="qa-group@zimbra.com"
	GOOD_RESULT_EMAIL_DESTINATION="qa-group@zimbra.com"

	# Only run smoke tests
	TC_TYPE=""
	QA_LOGS="logs_all"
	EXECUTE_SOAP_XML $QA_XML_ROOT/soapvalidator .xml


	# Parse the results
	GATHER_RESULTS
	CREATE_RESULTS_QA_WEBSITE SOAP_all
	CREATE_RESULTS_EMAIL all

	
fi


# Done!
#
exit 0
