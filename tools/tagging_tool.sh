#!/bin/sh
# This script generates and pushes tags to be used for releases.
# This should NOT be used by any individual, only the releases build server should be running this.

# Annotation message
ANNOMESG="\"Laird Release Version $1\""

command_exists () {
	command -v "$1" > /dev/null  2>&1;
}

# Make sure version is given.
if [ $# -gt 2 ]; then
	echo "Illegal number of parameters."
	exit 1;
fi

# Make sure repo tool is in path.
command_exists repo
if [ $? -ne 0 ]; then
	echo "repo is required, exiting."
	exit 1
fi

# Make sure git tool is in path.
command_exists git
if [ $? -ne 0 ]; then
	echo "git is required, exiting."
	exit 1
fi

if [ -z "$1" ]; then
	echo "Tag version is missing, exiting.";
	exit 1;
else
	echo "Creating $1 tag"
	if ! [ -z "$2" ];	then
		ANNOMESG="\"${2}\"";
	fi
	echo "Tag message: $ANNOMESG"

	echo "Generating tags.."
	repo forall -c "git tag -a ${1} -m ${ANNOMESG}"
	if [ $? -ne 0 ]; then
		echo "Failed to create annotated tag. Please investigate."
		exit 1
	fi

	repo forall -c "git push origin ${1} --follow-tags"
	if [ $? -ne 0 ]; then
		echo "Failed to push annotated tag. Please investigate."
		exit 1
	fi
fi
