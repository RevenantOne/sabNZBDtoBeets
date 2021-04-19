#!/bin/bash

## TODO
# Find a better way to determine the status of the album (Pending exit codes)
# Find a way to auto upgrade MP3 with Flac

## Config
#  Script
logDir="$HOME/.sabNZBDtoBeets"
scriptLog="$logDir/scriptLog"
beetsLog="$logDir/beetsLog-"`echo $2 | tr -cd '[:alnum:]'`
musicDir="/home/media/music/stark/"
QAdir="/home/staging/qa"
dupesDir="$QAdir/Dupes/"
nomatchDir="$QAdir/NoMatch/"
beetsOutput="imported" #Defaults to imported (Needed until exit codes are a thing)

#  Beets
config="$HOME/.config/beets/configNoColor.yaml"

#  Lidarr
lidarrApi=`cat $HOME/.config/tokens/lidarr.api`
lidarrUrl="http://localhost"
lidarrPort="3086"

timestamp() {
	date +"[%F %T] "
}

# Rescan artist folders in Lidarr
updateLidarr() {
	# Look up the last updated artist
	artistLoc="$1"`beet ls -af %asciify{'$albumartist'} 'added:-1d..' added- | head -n 1`"/"

	# Call Lidarr API
	curl -Ls "$lidarrUrl":"$lidarrPort"/api/v1/command -d "{\"name\": \"RescanFolders\", \"folders\": [\"${artistLoc}\"]}" --header "X-Api-Key:$lidarrApi"
}

# Look for and delete specified file type
deleteFile() {
	if ls "$1"*".$2" > /dev/null 2>&1
	then
		echo $(timestamp) "Deleting all .$2 in $1" >>$scriptLog
		rm "$1"*".$2"
	fi
}

# Import album and get import status
if [[ "$5" == "music" ]]
then
	# Delete images, nfo, etc
	deleteFile "$1/" "jpeg"
	deleteFile "$1/" "jpg"
	deleteFile "$1/" "png"
	deleteFile "$1/" "nfo"
	deleteFile "$1/" "nzb"
	deleteFile "$1/" "m3u"
	deleteFile "$1/" "log"
	deleteFile "$1/" "srr"

	# Check for tar files and extract
	for i in "$1/"*.tar
	do
		if [ -f "$i" ]
		then
			tar -xf "$i" -C "$1" &
			wait $!
		fi
	done

	# Run beets
	echo $(timestamp) "Importing $3 with beets..." >>$scriptLog
	beet -c "$config" im -l "$beetsLog" -qm "$1" &
	wait $!

	# Determine the status of the album
	line=`tail -1 $beetsLog`
	firstWord=$(echo $line | cut -d ' ' -f 1)

	if [[ $firstWord != "import" ]]
	then
		if [[ "$line" == "skip $1" ||  "$line/" == "skip $1" ]]
		then
			beetsOutput="skip"
		elif [[ "$line" == "duplicate-skip $1" || "$line/" == "duplicate-skip $1" ]]
		then
			beetsOutput="duplicate-skip"
		fi
	# elif [[ "$firstWord" == "" ]]
	# then		
	# 	echo $(timestamp) "Error: Unable to determine album status. Exiting..." >>$scriptLog #TODO FIX THIS entire part
	# 	exit
	fi

	# Process an album depending on its status
	case "$beetsOutput" in
	"duplicate-skip")
		echo $(timestamp) "$3 already exists. Moving to QA dir." >>$scriptLog
		cp -r "$1" "$dupesDir$3" &
		wait $!
		rm -r "$1" &
		wait $!
		echo "Completed. [${0##*/}: Skipped - Duplicate]"
		;;
	"skip")
		echo $(timestamp) "$3 cannot be matched. Moving to QA dir." >>$scriptLog
		cp -r "$1" "$nomatchDir$3" &
		wait $!
		rm -r "$1" &
		wait $!
		echo "Completed. [${0##*/}: Skipped - No Match]"
		;;
	"imported")
		# Successful import notice unavailable afaik. Defaults to success.
		echo $(timestamp) "$3 has been imported." >>$scriptLog
		rm -r "$1" &
		wait $!
		echo "Rescanning artist folders for Lidarr..." >>$scriptLog
		updateLidarr "$musicDir"
		wait $!
		echo ""
		echo "Completed. [${0##*/}: Imported]"
		;;
	*)
		echo "Error!: "$beetsOutput
		echo $(timestamp) "DEBUG: $beetsOutput" >>$scriptLog
		echo $(timestamp) "Exit Code: $?" >> $scriptLog
		;;
	esac

else
	echo $(timestamp) "Error $3" >>$scriptLog
fi

# Clean and confirm
#rm $beetsLog
echo $(timestamp) "Script complete." >>$scriptLog
