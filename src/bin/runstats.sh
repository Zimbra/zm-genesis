#!/bin/ksh


COMMAND_LINE="$0 $*"
if [ $# -ne 2 -a $# -ne 3 ]
then
	echo "You typed: $COMMAND_LINE"
	echo "Usage: $0 <zimbra home> <ZimbraQA dir> [ <qaweb path> ]"
	echo "  <zimbra home>: the zimbra install dir (i.e. /opt/zimbra)"
	echo "  <qa home>: the location of the QA scripts (i.e. /p4/main/ZimbraQA)"
	echo "  <qa home>: the path of the QA webpage files (i.e. /space/sambashare/qaweb) (optional)"
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

QA_RESULTS=$QA_ROOT/results


runtop() {

	INTERVAL=5
	COUNT=`expr $DURATION / $INTERVAL`

	echo "Running top -b -i $INTERVAL $COUNT ..."
	top -b -i -d $INTERVAL -n $COUNT >>$QA_RESULTS/top.out 2>>$QA_RESULTS/top.err

}


runvmstat() {

	INTERVAL=6
	I=`expr $INTERVAL \* 10`
	COUNT=`expr $DURATION / $I`

	while [ $COUNT -gt 0 ]; do
		echo "Running vmstat $INTERVAL 10 ($COUNT more times) ..."
		date >> $QA_RESULTS/vmstat.out
		vmstat $INTERVAL 10 >>$QA_RESULTS/vmstat.out 2>>$QA_RESULTS/vmstat.err
		COUNT=`expr $COUNT - 1`
	done

}


# How many seconds should the script run for?
#
DURATION=3600 # 3600 = 1 hour

# Make sure the log directory exists
#
if [ ! -d $QA_ROOT ]; then
	echo "$QA_ROOT does not exist ... sending output to /tmp"
	QA_RESULTS=/tmp
fi

if [ ! -d $QA_RESULTS ]; then
	mkdir -p $QA_RESULTS || {
		echo "Unable to mkdir $QA_RESULTS ... using /tmp"
		QA_RESULTS=/tmp
	}
fi

runtop &
runvmstat &


exit 0
