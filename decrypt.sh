#!/bin/bash

# Programmer: Vishal A Patel
#
# This script will decrypt all of the files in a given folder
#	NOTE: The files must have been encrypted using the 'encrypt.sh'
#		script in order for this to work...
#
# The steps performed in this script are as follows:
#	1) Prompt the user for a folder name
#	2) Check if folder exists...
#	3) get the expected passphrase
#	4) attempt to decrypt the files ( error checking is performed after attempting to decrypt each file )
#	5) extract the file name from each file after it is decrypted
#	6) rename the file to the extracted file name
#	7) ask if the user wants to compare checksums, if so, get the checksum of current folder items, and compare
#		with the checksum in the text file...
#	8) end of script
#


CHECKSUMFILE=checksum.txt

function checkIfDirectoryExists {
	CURRENTDIRECTORY=$1

	if [ ! -d $CURRENTDIRECTORY ]; then
		echo $CURRENTDIRECTORY DNE...
		exit
	fi
}

function extractFileName {
	# save the current file name
	CURRENTFILE=$1

	# the file name starts with '^__', use sed to locate it...
	EXTRACTEDFILENAME="$(sed -n '/\^__/p' $CURRENTFILE)"

	# get rid of the first three chars in the file name...
	EXTRACTEDFILENAME="$(echo $EXTRACTEDFILENAME | sed 's/^.\{3\}//')"

	# sed to delete the file name...
	sed -i '/\^__/d' $CURRENTFILE

}

function decryptFiles {
	echo Attempting to decrypt files...

	for FILE in `ls $FOLDERNAME`; do
		if [ $FILE != "checksum.txt" ]; then
			FILENAME="`echo $FILE | cut -d. -f1`.tmp"
			OUTPUT="$(echo $PASSPHRASE | gpg2 --batch --passphrase-fd 0 --quiet -d $FOLDERNAME/$FILE 2>&1 > $FOLDERNAME/$FILENAME)"
			if [[ $OUTPUT =~ "failed" ]]; then
				echo ERROR: maybe wrong passphrase?
				`rm -f $FOLDERNAME/$FILENAME`
				exit
			else
				# remove the ._ file ( the encrypted version of the file )
				`rm -f $FOLDERNAME/$FILE`
				# extract the file name from the new .tmp file
				extractFileName $FOLDERNAME/$FILENAME
				# rename the .tmp file to the extracted file name
				mv $FOLDERNAME/$FILENAME $FOLDERNAME/$EXTRACTEDFILENAME
			fi
		fi
	done
	echo Decryption complete...

}

function compareCheckSums {

	ORIGINAL_CHECKSUM="$(cat $FOLDERNAME/$CHECKSUMFILE | awk '{print $1}')"
	#NEW_CHECKSUM=`find bogusFiles/ -type f ! -name '$CHECKSUMFILE' -exec md5sum {} \; | sort -k 2 | awk '{ print $1}' | md5sum`
	NEW_CHECKSUM="$(find $FOLDERNAME -type f ! -name 'checksum.txt' -exec md5sum {} \; | sort -k 2 | awk '{ print $1}' | md5sum | awk '{print $1}')"
	echo $ORIGINAL_CHECKSUM
	echo $NEW_CHECKSUM

	if [ "$ORIGINAL_CHECKSUM" == "$NEW_CHECKSUM" ]; then
		echo THE CHECKSUMS MATCH
	else
		echo ERROR: CHECKSUMS DO NOT MATCH
	fi
}


#################################################
#		BEGIN SCRIPT			#
#################################################

echo Enter the Desired Directory \(NOTE: the directory should have been encrypted using the encrypt.sh script\)
read USERDIRECTORY
checkIfDirectoryExists $USERDIRECTORY

echo Enter the expected passphrase: 
read -s PASSPHRASE
decryptFiles

echo compare checksums \(y\/n\): 
read RESPONSE

if [ $RESPONSE == 'y' ]; then
	compareCheckSums
fi
echo COMPLETED DECRYPTION PROCESS

