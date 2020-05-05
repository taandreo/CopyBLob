#!/bin/bash

# v1.0 Author: Tairan Andreo

# Require root privileges to run this program
(( EUID != 0 )) && echo "You need to have root privileges to run this program!" && exit 1

# Make a tmp folder
mkdir .tmp-azcopy

# Download az copy
wget -O .tmp-azcopy/azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux -q

# install az copy
tar -zxf .tmp-azcopy/azcopy_v10.tar.gz --strip-components=1 -C .tmp-azcopy/

if test -f /usr/bin/azcopy; then
    echo -n "Another executable \"azcopy\" was found in /usr/bin, do you want overwrite ? [Y/N] (Enter = Y): "
    read OPTION
    if test $OPTION = 'N'; then
        rm -rf .tmp-azcopy/
        echo Exiting ... && exit 1
    elif test $OPTION != 'Y'; then
        rm -rf .tmp-azcopy/
        echo Invalid Option, Exiting ... && exit 1
fi

mv -f .tmp-azcopy/azcopy /usr/bin/azcopy
chown root:root /usr/bin/azcopy && chmod 755 /usr/bin/azcopy

rm -rf .tmp-azcopy/
