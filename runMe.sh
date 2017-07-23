#!/bin/bash
#
# The MAIN script
#
#

####
#
# The config file
#
###

CONFIG_FILE=./CONFIG_FILE


###
#
# The Scripts
#
###

TEST_API=./scripts/testAPI.sh
GPIO=./scripts/useGPIO.sh


###
#
# Test to make sure the files
# are where they supposed to be
#
###

if [[ -f $CONFIG_FILE  && -f $TEST_API && -f $GPIO ]]
# if they do
then
        # source the needed files
	source $CONFIG_FILE
        source $GPIO

# if one of them doesn't exist
else
        # exit with an error
        exit 1
fi



##########
#
# The following section is to insure that there is only 
# 1 instance of this script running at any point in time
#
##########

# The location to store the PID file
# by default it's stored on a tmpfs partiton (/dev/shm)
# that only exist in memory to avoid unecessary access to the SDCard
PID_FILE=/dev/shm/runMe_rpi_restless.pid

#debug
if [ $DEBUG = true  ] 
then
	echo "the PID for this process is :: $$"
fi


# check if the file exists
if [ -f $PID_FILE  ]

# if it does exist
then
	# set the PID variable the value stored in the PID_FILE
	PID=$(cat $PID_FILE)
	
	# check to see if a process is already running with this PID
	ps -p $PID > /dev/null 2>&1

	# if there is one
	if [ $? -eq 0 ]
	then
		#debug
		#echo "Process already running"
		if [ $DEBUG = true  ]        
		then
			echo "Process already running"
		fi

		# exit with an error
		exit 2 # process already running
	else
	# no process is running with the tested PID, 
	# we can assume that this script isn't running
	
		# copy the PID of the process running
		# this script into the PID_FILE
		echo $$ > $PID_FILE
		
		# if it can't write to the file (for whatever reason)
		if [ $? -ne 0 ]
		then	
			#debug
			if [ $DEBUG = true  ]        
			then
				echo "Cannot create PID file"
			fi
	
			# exit with an error	
			exit 1 # cannot create the pid file
		fi
	fi
# if it doesn't exist
else
	# copy the PID of the process running
	# this script into the PID_FILE
	echo $$ > $PID_FILE

	# if it can't create the file (for whatever reason)
	if [ $? -ne 0 ]
	then
		#debug
		if [ $DEBUG = true  ]
		then
			echo "Cannot create PID file"
		fi
	
		# exit with an error    
		exit 1 # cannot create the pid file
	fi
fi


#####
#
# This section actually runs the test
#
#####

# variable to hold the test result
test_fails=true

# set the GPIO_PIN mode
if [ $GPIO_ALERT = true ]
then
	gpio mode $GPIO_PIN out
fi


# while the test_fails variable is true
while [ $test_fails = true ]
do
	# run the script that tests the API
	$TEST_API
	test_result=$?
	
	# if its exit code is 0 (target is online)
	if [ $test_result -eq 0 ]
	then
	        if [ $DEBUG = true  ] 
	        then
			echo "..:: ONLINE ::.."
        	fi

                # reset the test_fails variable
                # to false to stop the loop
                test_fails=false
	
		# stop the alert
                # >>> do something here
                if [ $GPIO_ALERT = true ]
                then
			# set the GPIO_PIN low
			gpio write $GPIO_PIN 0 
                fi
	
	
	# if exit code is 1 (CONFIG_FILE not found)
	elif [ $test_result -eq 1  ]
	then
                if [ $DEBUG = true  ]
                then
                        echo "The CONFIG_FILE for the script $( basename $TEST_API )"
                        echo "located here : $TEST_API"
                        echo "could NOT BE FOUND !"
                fi
	
		# exit with an error
		exit 1
	
	# if exit code is 2 (target API is unreachable)
	elif [ $test_result -eq 2  ]
	then	
                if [ $DEBUG = true  ]
                then
                        echo "!!!!.. OFFLINE ..!!!!"
                fi

        
                # trigger an  the alert
                # >>> do something here
		if [ $GPIO_ALERT = true ]
		then
			# set the GPIO_PIN high
                	gpio write $GPIO_PIN 1
		fi


                # sleep for few seconds
                sleep $SLEEPING_TIME
	

	# if the exit code is not 0, 1 or 2 then
	# it's an unknown error 	
	else
		if [ $DEBUG = true  ]
                then
                        echo "an unknown error has occured !!!"
                fi
		
		# exit with an error
		exit 1
	fi
done

# exit gracefully
exit 0
