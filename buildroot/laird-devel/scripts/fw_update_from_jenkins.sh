#!/bin/bash
# This is a template script written as an example of how to automate
# the update of a wb45n board from Jenkins build. This script should
# form the basis of the first Jenkins regression test.

# Jenkins variables
: ${JENKINS_BUILD_NUMBER:=23}
: ${JENKINS_JOB_NAME:=wb45n_devel-trunk}
: ${JENKINS_URL:=http://natasha.corp.lairdtech.com/jenkins}

# per host system variables
: ${PUBLISH_DIR:=/var/www/jenkins}
: ${PUBLISH_BASE_URL:=http://beast/jenkins}

# per wb45n board variables
: ${WB45N_ADDRESS:=192.168.100.111}

# buildroot target name
: ${BUILDROOT_TARGET_NAME:=wb45n_devel}

set -e

mkdir -p "$PUBLISH_DIR/$JENKINS_JOB_NAME/$JENKINS_BUILD_NUMBER"
cd "$PUBLISH_DIR/$JENKINS_JOB_NAME/$JENKINS_BUILD_NUMBER"

# get the files from jenkins and unzip
if [ ! -e latest.zip ]; then
    wget $JENKINS_URL/job/$JENKINS_JOB_NAME/$JENKINS_BUILD_NUMBER/artifact/wb/images/$BUILDROOT_TARGET_NAME/latest/*zip*/latest.zip
else
    echo "Skipping file download and unpacking"
fi
unzip -ju latest.zip

# create the fw.txt file
echo "Creating fw.txt"
echo -n > fw.txt
for f in bootstrap.bin u-boot.bin kernel.bin rootfs.bin; do
    if [ -e $f ]; then
        if [ $f = "bootstrap.bin" -o $f = "u-boot.bin" ]; then
            echo -n "#" >> fw.txt
        fi
        echo "$PUBLISH_BASE_URL/$JENKINS_JOB_NAME/$JENKINS_BUILD_NUMBER/$f `md5sum $f | cut -d ' ' -f 1`" >> fw.txt
    fi
done
cat fw.txt

echo "Connecting to the wb45n device" 
ssh-copy-id root@$WB45N_ADDRESS
if [ yes != "`ssh root@$WB45N_ADDRESS cat /jenkins_update`" ]; then
    echo "ERROR: /jenkins_update doesnt exist or doesnt contain yes"
    exit 1
fi
ssh root@$WB45N_ADDRESS fw_update --url $PUBLISH_BASE_URL/$JENKINS_JOB_NAME/$JENKINS_BUILD_NUMBER/fw.txt
