#!/bin/bash

#Make shure that mailserver is running
if ps aux | grep "[_]postfix" > /dev/null
then
    echo "Postfix Mailserver is running"
else
    echo "Postfix Mailserver must be started - Password required, if not yet superuser!"
    sudo Postfix start
fi

# Grab config from local file
source config.txt

echo -e "Running build test"
ruby build.rb
