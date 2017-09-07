#!/bin/sh -x
#

#
# New version of runtests that doesn't use STAF/STAX
#
#  This script runs the nightly tests.
#
# Usage: runtest.sh <builddir>
#   where <builddir> is the base of directory that the build is going into.
#   for example, /home/build/builds/20041028100132


#
# usage check
if [ $# -ne 2 ]
then
        echo "You typed: $0 $*"
        echo "Usage: $0 <builddir> <admin_password>"
        echo "    where <builddir> is the directory where the build resides"
        echo "    where <admin_password> is the system administrator password"
        exit 1
fi


WORKING=$1
ADMIN_PASSWORD=$2
TIMESTAMP=`echo $WORKING| awk -F/ '{print $NF}'`

BUILD_ROOT=$WORKING
QA_ROOT=$BUILD_ROOT/ZimbraQA
RESULTS_ROOT=$QA_ROOT/results
QTP_FLAG_FILE=$RESULTS_ROOT/QTPFlag.txt

# Check whether the results folder is created
if [ ! -d $RESULTS_ROOT ]; then
	mkdir -p $RESULTS_ROOT || {
		echo "Unable to mkdir -p $RESULTS_ROOT"
		exit 1
	}
fi



# Create a domain with the appropriate users
CREATE_DOMAIN()
{
	
	testDomain="$1"

	#
	# Check if domain exists
	#
	/opt/zimbra/bin/zmprov gd "$testDomain" > /dev/null 2>&1
	domainExists=`echo $?`

	#
	# If domain exists delete the domain
	#
	if [ "$domainExists" = 0 ]
	then
		#
		# Before deleting the domain check if the domain is empty
		# Non-empty domain cannot be deleted
		# Get all users on that domain
		#
		userList=`/opt/zimbra/bin/zmprov gaa $testDomain`

		#
		# Declare an array which stores all the users on the test domain
		#
		declare -a usersOnDomain

		#
		# Move all users in the list to the array after removing line feeds
		#
		usersOnDomain=( `echo "$userList" | tr '\n' ' '`)

		#
		# Delete all users in that domain
		#
		for i in "${usersOnDomain[@]}"
		do
			/opt/zimbra/bin/zmprov da "$i"  > /dev/null 2>&1
		done	

		#
		# Now delete the domain
		#
		/opt/zimbra/bin/zmprov dd "$testDomain" > /dev/null 2>&1
	fi

	#
	# Now check if the domain still exists
	#
	/opt/zimbra/bin/zmprov gd "$testDomain" > /dev/null 2>&1
	domainExists=`echo $?`

	#
	# If domain does not exist create the test domain afresh
	#
	if [ "$domainExists" > 0 ]
	then
		echo "Cleanup of $testDomain successful"
		/opt/zimbra/bin/zmprov cd "$testDomain" > /dev/null 2>&1
		domainCreated=`echo $?`

		#
		# Check if the domain has been created successfully
		#
		if [ "$domainCreated" = 0 ]
		then
			/opt/zimbra/bin/zmprov gd "$testDomain" > /dev/null 2>&1
			domainExists=`echo $?`
			
			#
			# Initialize the usernames here OR
			#+ Get the usernames from a file
			#
			userArray=( user01 user02 user03 user04 user05 user06 user07 user08 user09 user10 user11 user12 user13 user14 user15 )

			#
			# If domain now exists then create the test users
			#
			if [ "$domainExists" = 0 ]
			then
				for i in "${userArray[@]}"
				do
					#
					# Create the username to create by joining the user and domain strings
					#+ and create the users
					userToCreate=$i"@"$testDomain
					/opt/zimbra/bin/zmprov ca "$userToCreate" test123 > /dev/null 2>&1
				done
				echo "Setup of $testDomain successful"
			fi
			else
				echo "Setup of $testDomain failed"
				exit 1
		fi
	else
		echo "Cleanup of $testDomain failed"
		exit 1
	fi


}

INIT_SERVER()
{

	# Create the domains
	#
	for i in testdomain.com testdomain1.com testdomain2.com; do
		CREATE_DOMAIN $i
	done
	
}


CREATE_QTP_FLAG_FILE()
{

	# Truncate the file so we start from scratch
	#
	rm -f $QTP_FLAG_FILE || {
		echo "Unable to clean up previous $QTP_FLAG_FILE"
		# Continue processing, hope for the best
	}

	# Insert the build ID
	echo "Build: $TIMESTAMP" >> $QTP_FLAG_FILE || {
		echo "Unable to echo into $QTP_FLAG_FILE"
		exit 1
	}

	# Insert the admin password
	echo "Admin Password: $ADMIN_PASSWORD" >> $QTP_FLAG_FILE || {
		echo "Unable to echo into $QTP_FLAG_FILE"
		exit 1
	}

}



INIT_SERVER
CREATE_QTP_FLAG_FILE

# Done!
#
exit 0

