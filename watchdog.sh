
#!/bin/bash

# Watchdog script to be called by a cron job
# which performs these checks / tasks:
#
#  1) Checks if the server is still running
#  2) Checks for updates via GIT
#

SCRIPT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TEST_GIT_REMOTENAME=origin
TEST_GIT_BRANCHNAME=master
SCREEN_SESSION="hans-ci"

# fetch latest build system version
cd $SCRIPT_PATH

# only update if system is not running
if [ -a ".lockfile" ]
then
  echo -e "Running, abort."
  exit 0
fi

# end the system
pkill -f 'ruby build.rb'
# end any screen session that might be hosting it
screen -S $SCREEN_SESSION -X quit

# system is not building, run update
git fetch $TEST_GIT_REMOTENAME
git diff $TEST_GIT_REMOTENAME/$TEST_GIT_BRANCHNAME --exit-code
RETVAL=$?
# if the diff value is zero nothing changed - abort
[ $RETVAL -eq 0 ] && exit 0
# there is a relevant diff, update
echo -e "\0033[34mFetching latest build system version\0033[0m\n"
git pull $TEST_GIT_REMOTENAME $TEST_GIT_BRANCHNAME || exit 1

# start a new screen session called hans-ci
screen -dmS $SCREEN_SESSION
# Issue the ./run.sh command inside that session
screen -S $SCREEN_SESSION -p 0 -X stuff $'./run.sh\n'
