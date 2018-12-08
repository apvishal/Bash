#!/bin/bash

. analyze.sh
# Programmer: Vishal A Patel
#
# This script will take take a user specified foldername (or path) and encrypt the files.
# The Steps performed are as follows:
#	1) Prompt the user for a folder name
#	2) verify folder exists (exit if not)
#	3) grab the checksum of each file, then compute the checksums on all checksums, 
#	4) store the final checksum into a file ( checksum.txt )
#		NOTE: we want a checksum of the files before we modify the files...
#	5) use sed to inject the filename into the file itsself ( this is so we know what to name
#		the file when we decrypt it )
#	6) encrypt each file (one at a time) and rename the output file to a valid timestamp
#		and append a ._ extention to it
#	7) end of script

# NOTE: use the following command to cat this file out so we can write a new portion of the script 
# 	to check the commands and version numbers to let the user know whether or not the script will work
#			awk '/pattern1/ {p=1}; p; /pattern2/ {p=0}' file
#

###BEGIN_INFO
# gpg2		2.2.6
# md5sum	8.29
# date		8.29
# sed		4.5
# awk		4.2.1
# shuf		8.29
###END_INFO
TIMESTAMP=`date "+%M%d%y%H%M%S"`

function checkAnalysisFlag {
	if [[ "$ANALYSIS_RESULT" -eq "1" ]]; then
		echo ALL COMMANDS AND VERSIONS....OK
	else
		echo ERROR: THERE WAS AN ERROR WITH COMMANDS AND VERSION NUMBERS...
		echo check commands before proceeding...
		exit
	fi
}	
function updateTimeStamp {

	# the current working directory...
	FOLDER=$1
	# loop until we get a timestamp that doesnt exist...
	while true;
	do
		# first update the timestamp...
		TIMESTAMP=`date "+%M%d%y%H%M%S"`

		# make sure a file with this timestamp doesnt already exist...
		RESULTS=`ls -ltr $FOLDER | grep $TIMESTAMP`

		# check if the string is empty, if it is, then no such file name exist..
		if [ -z "$RESULTS" ]; then
			# this is a good timestamp, leave the loop
			break
		else
			# go on to next iteration of loop to make a new timestamp...
			continue
		fi
	done
	#echo NEWTIMESTAMP: $TIMESTAMP

}

function injectFileName {
	# save file name...
	FILENAME=$1
	NAME=`basename $FILENAME`

	# get the length of the file
	FILE_LENGTH="$(cat -n $FILENAME | wc -l)"

	# use shuf to generate a random number frorm 1 - FILE_LENGTH
	FILENAME_POSITION="$(shuf -i 1-$FILE_LENGTH -n 1)"

	#inject the filename into the file itself...
	`sed -i "$FILENAME_POSITION i\^__\$NAME" "$FILENAME"`

}

function getFolderName {
	echo "Enter the name of the desired folder..."
	read FOLDERNAME
	if [ ! -d $FOLDERNAME ]; then
		echo $FOLDERNAME dne...
		exit;
	fi
}
function getCheckSum {
	
	# first check if a checksum file already exist... if so, delete it
	if [ -f $FOLDERNAME/checksum.txt ]; then
		echo found checksum file, deleting it and making a new one
		rm $FOLDERNAME/checksum.txt
	fi
	
	# found this idea on stack over flow...
	CHECKSUM=$(find $FOLDERNAME -type f -exec md5sum {} \; | sort -k 2 | awk '{ print $1}' | md5sum)

	# store the checksum into the folder...
	echo $CHECKSUM > $FOLDERNAME/checksum.txt
}
function encryptFiles {
	# first, we need the users passphrase
	echo Enter your passphrase \(REMEMBER YOUR PASSPHRASE\): 
	read -s PASSPHRASE
	# let user know we about to encrypt the files
	echo Encrypting files...
	# loop to encrypt each file
	for FILE in `ls $FOLDERNAME`; do
		if [ $FILE != "checksum.txt" ]; then
			# inject the file name into the file ( we will rename the file when encrypting...)
			injectFileName $FOLDERNAME/$FILE
			# update the time stamp to use it as a new file name...
			updateTimeStamp $FOLDERNAME
			#`echo $PASSPHRASE | gpg2 --batch --passphrase-fd 0 --output $FOLDERNAME/$FILE._ -c $FOLDERNAME/$FILE`
			#echo "ENCRYPT $FOLDERNAME/$FILE as $FOLDERNAME/$FILE._ "
			`echo $PASSPHRASE | gpg2 --batch --passphrase-fd 0 --output "$FOLDERNAME/$TIMESTAMP._" -c $FOLDERNAME/$FILE`
			# remove the original file...
			`rm -f $FOLDERNAME/$FILE`
		fi

	done
	echo File encryptions completed...
}
###############################################################################
#				BEGIN SCRIPT				      #
###############################################################################

# first check if the current environment has the correct commands and versions...
analyze "$(awk '/###BEGIN_INFO/ {p=1}; p; /###END_INFO/ {p=0; exit;}' $0)"
checkAnalysisFlag
# get the name of the folder whose contents the user wants to encrypt...
getFolderName
# get the checksum of the all checksums from the folder 
getCheckSum
# encrpyt all files...
encryptFiles
