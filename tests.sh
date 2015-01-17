#!/bin/bash

# Initialize environment
. config.txt

# Run tests
ruby unittests/tc_bucket.rb
ruby unittests/tc_cam.rb
