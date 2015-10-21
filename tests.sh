#!/bin/bash

# Exit on error
set -e

# Initialize environment
. config.txt

# Run tests
ruby unittests/tc_bucket.rb
ruby unittests/tc_mail.rb
ruby unittests/tc_octokit.rb
ruby unittests/tc_resultpage.rb
ruby unittests/tc_cam.rb
