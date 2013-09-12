#!/bin/bash
# This is a template script written as an example of how to automate
# the update of a wb45n board from Jenkins build. This script should
# form the basis of the first Jenkins regression test.

# Jenkins variables
: ${JENKINS_BUILD_NUMBER:=141}
: ${JENKINS_JOB_NAME:=wb45n_devel-trunk}
: ${JENKINS_URL:=http://natasha.corp.lairdtech.com/jenkins}

# per host system variables
: ${PUBLISH_DIR:=/var/www/scratch/autotest}
: ${PUBLISH_BASE_URL:=http://10.1.44.227/scratch/autotest}

# per wb45n board variables
: ${WB45N_ADDRESS:=10.1.44.161}

# buildroot target name
: ${BUILDROOT_TARGET_NAME:=wb45n_devel}

set -e

SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

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

echo "Check that u-boot has: jenkins_update=yes"
if [ "`sshpass -psummit $SSH root@$WB45N_ADDRESS fw_printenv jenkins_update`" != 'jenkins_update=yes' ]; then
    echo "ERROR: u-boot var jenkins_update doesnt exist or doesnt contain yes"
    exit 1
fi

echo "Start the upgrade process"
sshpass -psummit $SSH root@$WB45N_ADDRESS fw_update --url $PUBLISH_BASE_URL/$JENKINS_JOB_NAME/$JENKINS_BUILD_NUMBER/fw.txt

echo "Wait 60 seconds for the reboot"
sleep 60

echo "Check that the upgrade worked"
rel=`sshpass -psummit $SSH root@$WB45N_ADDRESS cat /etc/summit-release`
echo "/etc/summit-release=$rel"
if [ "$rel" = "Laird Linux jenkins-${JENKINS_JOB_NAME}-${JENKINS_BUILD_NUMBER}" ]; then
    echo "Upgrade worked."
    exit 0
else
    echo "Upgrade FAILED!"
    exit 1
fi
