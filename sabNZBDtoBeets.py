#!/usr/bin/python3.8
import datetime
import os
import requests
import re
import pathlib
import tarfile
import subprocess
import sys
import shutil

debug=True

try:
    (scriptname, directory, orgnzbname, jobname, reportnumber, category, group, postprocstatus, url) = sys.argv
except:
    print("Cannot connect to sabNZBd.")
    if debug == True:
        print("Using debug values...")
        scriptname='/usr/share/sabnzbdplus/scripts/sabNZBDtoBeets.py' #arg1
        orgnzbname='Sonic Youth - The Eternal (2009) MP3' #arg3
        directory='/home/staging/downloads/music/' + orgnzbname + '/' #arg2
        jobname=orgnzbname.replace(' ', '') #arg4
        # reportnumber='1' #arg5
        category='music' #arg6
    else:
        print("Exiting...")
        sys.exit(1)

## Config
#  Script vars
homeDir=os.environ['HOME']
logDir=homeDir+'/.sabNZBDtoBeets'
scriptLog=logDir + '/scriptLog'
beetsLog=logDir + '/beetsLog-py-' + re.sub('[\W_]+', '',jobname)
musicDir='/home/media/music/stark/'
QAdir='/home/staging/qa'
dupesDir=QAdir + '/Dupes/'
nomatchDir=QAdir + '/NoMatch/'
beetsOutput='imported' # ! Defaults to imported (Needed until exit codes are a thing)
unwantedFiles=[".jpeg",".jpg",".png",".nfo",".nzb",".m3u",".srr"]

#  Beets
beetsConfig=homeDir+'/.config/beets/configNoColor.yaml'

#  Lidarr
lidarrApi = open(homeDir+'/.config/tokens/lidarr.api').read().strip()
lidarrUrl='localhost'
lidarrPort='3086'

## Functions
def timestamp():
    now = datetime.datetime.now()
    print('[' + now.strftime('%Y-%m-%d %H:%M:%S') + '] ')
    return

def updateLidarr(lidarrUrl, lidarrPort, lidarrApi):
    # Check beets for last added artist
    scanArtist=os.popen("beet ls -af %asciify{'$albumartist'} 'added:-1d..' added- | head -n 1").read().rstrip('\n')
    #----- This will work if it's always the last album added by beets. Add confirmation the nzb and last added are the same.
    # Call Lidarr API
    lidarrAPIURL=lidarrUrl + ":" + lidarrPort + "/api/v1/command"
    
    # Request update of directory
    params = (('apiKey', lidarrApi),)
    data = '{"name": "RescanFolders", "folders": ["/home/media/music/stark/' + scanArtist + '/"]}'
    #----- Need to confirm above dir exists first as it will rescan entire dir otherwise
    response = requests.post('http://' + lidarrUrl + ':' + lidarrPort + '/api/v1/command', params=params, data=data)

    # Check reponse of request
    if response.status_code != 201:
        print("Error. Refresh Artist Folder Failed: " + str(response.status_code))

def cleanUp(filePath):
    fileList = os.listdir(filePath)

    for file in fileList:
        fileExt = pathlib.Path(file).suffix
        fileName = pathlib.Path(file).name

        if fileExt in unwantedFiles:
            print("Deleting " + fileName + "...")
            os.remove(filePath + '/' + fileName)

        if fileExt == ".tar.gz":
            tar = tarfile.open(filePath + '/' + fileName)
            tar.extractall()
            tar.close()

# Import album
if category == 'music':
    # Remove unwanted files
    cleanUp(directory)

    # Run beets
    try:
        beetsCommand = subprocess.run(['beet', '-c', beetsConfig, 'im', '-l', beetsLog, '-qm', directory], stdout=subprocess.PIPE)
    except:
        print("Error running beets")

    # Determine the status of the album
    # ! Log file has to be used due to lack of exit codes/saying what it's doing
    beetsArgs = beetsCommand.stdout.decode("utf-8").split('\n')
    beetsOutput = open(beetsLog).read().split('\n')[1].split(' ')[0]
    beetsReturnCode = beetsCommand.returncode
    scriptnameShort = scriptname.split('/')[5]

    # Ugh
    if beetsOutput == '':
        beetsOutput = 'imported'

    if debug == True:
        print(beetsArgs)
        print(beetsOutput)
        print(beetsReturnCode)

    if beetsOutput == "skip":
        print(orgnzbname + " cannot be matched. Moving to QA dir.")
        shutil.move(directory,nomatchDir)
        print("Completed. [" + scriptnameShort + " - Skipped: No Match]" )
    elif beetsOutput == "duplicate-skip":
        print(orgnzbname + " already exists. Moving to QA dir.")
        shutil.move(directory,dupesDir)
        print("Completed. [" + scriptnameShort + " - Skipped: Duplicate]" )
    elif beetsOutput == "imported":
        print(orgnzbname + " has been imported.")
        print("Refreshing artist in Lidarr.")
        try:
            updateLidarr(lidarrUrl, lidarrPort, lidarrApi)
        except:
            print("Failed to update Lidarr")
        # os.remove(directory)
        shutil.rmtree(directory)
        print("Completed. [" + scriptnameShort + " - Imported]" )
    else:
        print("Invalid output: " + beetsOutput)

    # Clean up
    # os.remove(beetsLog)

# timestamp()
updateLidarr(lidarrUrl, lidarrPort, lidarrApi)