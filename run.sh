#!/bin/bash

uname_system=`uname`

if [ uname_system == "Darwin" ]
then
	# Make shure that mailserver is running
	if ps aux | grep "[_]postfix" > /dev/null
	then
    		echo "Postfix Mailserver is running"
	else
    		echo "Postfix Mailserver must be started - Password required, if not yet superuser!"
    		sudo Postfix start
	fi
fi

# Grab config from local file
source config.txt
source $HOME/.profile

# Delete any remaining left-over lockfiles
rm -rf .lockfile*

echo -e "Running build test"
ruby build.rb
