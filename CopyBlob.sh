#!/bin/bash

# v1.0 Author: Tairan Andreo

STORAGE=''
CONTAINER=''
BLOB_PATH=''
SOURCE_DIR=''
SAS=''


CONT_LINK="https://$STORAGE.blob.core.windows.net/$CONTAINER$SAS"
LOG_FILE="/var/log/azcopy/azcopy_$(date +%F).log"

# Require root privileges to run this program
(( EUID != 0 )) && echo "You need to have root privileges to run this program!" && exit 1

Main(){
    # Ensure that the log folder is created
    mkdir -p /var/log/azcopy

    # Make a container
    azcopy make $CONT_LINK >> $LOG_FILE

    # Create a variable with all files
    FILES=$(find $SOURCE_DIR -iname 'log*')

    # Copy all *.log files of a directory to a blob container.'
    GenTitle "START BACKUP"

    for PATH_FILE in $FILES; do
        GenLink $PATH_FILE
        echo >> $LOG_FILE && GenLog "Starting copy for $PATH_FILE:"
        azcopy copy --overwrite ifSourceNewer $PATH_FILE $LINK >> $LOG_FILE
    done

    # Remove file whith modification time greater than 24h, and already available on the blob.
    GenTitle "REMOVE OLD FILES"

    RM_FILES=$(find $SOURCE_DIR -iname 'log*' -mtime +0)

    for PATH_FILE in $RM_FILES; do
        GenLink $PATH_FILE
        LINK_TEST=$(azcopy ls $LINK)
        if test -n "$LINK_TEST"; then
            GenLog "$PATH_FILE exist in blob, removing from local folder"
            GenLog $(rm -v $PATH_FILE)
        fi
    done

}


GenLog(){
    echo "$(date '+%F %T') $1" >> $LOG_FILE
}

GenTitle(){
    echo "############################################" >> $LOG_FILE
    echo "$(date '+%F %T') $1" >> $LOG_FILE
    echo "############################################" >> $LOG_FILE
}


GenLink(){
    YEAR=$(date -r $1 +%Y)
    MONTH=$(date -r $1 +%B)
    DATE=$(date -r $1 +%F)

    FILE=$(echo $1 | awk -F/ '{print $NF}')
    LINK="https://$STORAGE.blob.core.windows.net/$CONTAINER/$BLOB_PATH/$YEAR/$MONTH/$DATE/$FILE$SAS"
}

Main