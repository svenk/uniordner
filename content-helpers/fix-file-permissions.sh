#!/bin/bash
#
# An interactive script which checks the current directory
# (which should be the uni root dir) for inapproriate settings.
# The root directory will be chosen automatically

# the mask everything should have
mask=0755

# what is checked in the find statement
findcheck="-a+r"

# this should go to Uni Root
pushd $(dirname `readlink -f $0`) > /dev/null
cd $(pwd)/..

echo "Checking Unix file permissions on Uni-Ordner: $(pwd)"
echo

echo "Defect files:"

files=$(mktemp)
find . ! -perm $findcheck | tee $files
num=$(cat $files | wc -l)

if [ $num -gt 0 ]; then
	read -p "Correct permissions to $mask? [Y/N] " -n 1
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
		echo "Aborted"
		rm $files
		exit 0
	fi
else
	echo "No defect permissions found."
	rm $files
	exit 0
fi

# do the work:

echo "Fixing perms for $num files"

cat $files | xargs -d"\n" -n1 -t chmod $mask 

rm $files
exit 0
