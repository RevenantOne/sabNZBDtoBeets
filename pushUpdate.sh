#!/bin/bash

echo "Updating live beets.sh post processing script..."
mv /usr/share/sabnzbdplus/scripts/sabNZBDtoBeets.sh /home/jarvis/scripts/sabNZBDtoBeets/sabNZBDtoBeets.bak
cp /home/jarvis/scripts/sabNZBDtoBeets/sabNZBDtoBeets.sh /usr/share/sabnzbdplus/scripts/sabNZBDtoBeets.sh
echo "Update complete."
