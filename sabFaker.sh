#!/bin/bash

## sh sabFaker.sh targetDirectory

## 1 The final directory of the job (full path)
## 2 The original name of the NZB file
## 3 Clean version of the job name (no path info and ".nzb" removed)
## 4 Indexer's report number (if supported)
## 5 User-defined category

scriptLoc="/home/jarvis/scripts/sabNZBDtoBeets/sabNZBDtoBeets.sh"
targetDir="$1"

for dir in "$targetDir"*
do
    one="$dir"
    two=`echo ${dir} | awk -F'/' '{ print $6 }'`
    three=`echo ${dir} | awk -F'/' '{ print $6 }'`
    four="1"
    five="music"

    # echo "sf1: " $one
    # echo "sf2: " $two
    # echo "sf3: " $three
    # echo "sf4: " $four
    # echo "sf5: " $five

    bash "$scriptLoc" "$one" "$two" "$three" "$four" "$five" &
    wait $!
done