#!/bin/bash

echo "Updating live beets.py post processing script..."
mv /usr/share/sabnzbdplus/scripts/sabNZBDtoBeets.py /home/jarvis/github/sabNZBDtoBeets/sabNZBDtoBeets.bak
cp /home/jarvis/github/sabNZBDtoBeets/sabNZBDtoBeets.py /usr/share/sabnzbdplus/scripts/sabNZBDtoBeets.py
echo "Update complete."
