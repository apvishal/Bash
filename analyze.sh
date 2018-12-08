#!/bin/bash

# Programmer: Vishal A Patel
# Purpose: 
#	this script will take as input a "file" (as a string) which will contain the commands
#	along with their version numbers...
#	the script will use these combinations to make sure that the current environment has all of
#	the correct commands and versions, the ANALYSIS_RESULT variable will be updated depending on the 
#	results...
#

# a global variable to determine whether or not all cmds and version numbers have passed...
# 1 for pass, 0 for fail
ANALYSIS_RESULT=1

function analyze {

	echo "*****************************************************************"
	# save the info passed to us, and parse out the irrelevant items...
	FILE="$(echo $1 | sed -e 's/###\([A-Z]*\)_INFO//g')"
	# echo $FILE
	# replace # with newlines...
	FILE="$(echo $FILE | sed -e 's/#/\n/g')"

	# SOURCE https://unix.stackexchange.com/questions/7011/how-to-loop-over-the-lines-of-a-file
	IFS=$'\n'       # make newlines the only separator
	set -f          # disable globbing
	for cmd in $FILE; do
	  echo "checking for $cmd"
	  checkIfCommandExists "$(echo $cmd | sed "s/^[ \t]*//")"
	  printf '\n'
	done
	echo "*****************************************************************"

}

function checkIfCommandExists {
	COMMAND_INFO=$1
	CURRENT_COMMAND="$(echo $COMMAND_INFO | cut -d' ' -f1)"
	COMMAND_VERSION="$(echo $COMMAND_INFO | cut -d' ' -f2)"
	
	RESULT="$(which $CURRENT_COMMAND 2> /dev/null)"

	if [ -z  $RESULT ]; then
		echo ERROR: $CURRENT_COMMAND DNE....
		ANALYSIS_RESULT=0
	else 
		echo OK: $CURRENT_COMMAND found...
		echo checking version of $CURRENT_COMMAND
		checkCommandVersion "$CURRENT_COMMAND" "$COMMAND_VERSION"
	fi
}

function checkCommandVersion {
	COMMAND=$1
	VERSION=$2
	# since we know the command exists... run it with the --version flag...
	VERSION_RESULTS="$($COMMAND --version 2> /dev/null)"

	# check if the string is empty.. which would indicate that --version flag is unknown
	if [ -z "$VERSION_RESULTS" ]; then
		echo "ERROR: could not retrieve version number for $COMMAND"
		AUDIT_RESULT=0
	else
		# we have some string as a result, check for the version number...
		if [[ "$VERSION_RESULTS" =~ $VERSION ]]; then
			# the string contains the version number...
			echo "OK found version number match..."
		else
			echo ERROR: did not find version number match...
			ANALYSIS_RESULT=0
		fi
	fi

}
