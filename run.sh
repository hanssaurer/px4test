#!/bin/bash

# Grab config from local file
source config.txt

echo -e "Running build test"
ruby build.rb
echo -e "Running flash / run test"
ruby runhwtest.rb
