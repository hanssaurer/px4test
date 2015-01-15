
#!/bin/bash

# Watchdog script to be called by a cron job
# which performs these checks / tasks:
#
#  1) Checks if the server is still running
#  2) Checks for updates via GIT
#

SCRIPT_PATH=$HOME/src/px4test
echo "SCRIPT: ${SCRIPT_PATH}"
TEST_GIT_REMOTENAME=origin
TEST_GIT_BRANCHNAME=master
SCREEN_SESSION="hans-ci"
LOCKFILE=".lockfile"

# fetch latest build system version
cd $SCRIPT_PATH

# only update if system is not running
if [ -f $LOCKFILE ]
then

  # check how old the lockfile actually is. Time out after 20 mins.
  filemtime=`stat -c %Y $LOCKFILE`
  currtime=`date +%s`
  diff=$(( (currtime - filemtime) ))
  echo "Lockfile age: $diff seconds"

	if (( diff > 60 * 12 ))
	then
  		rm -rf $LOCKFILE
	else
		echo -e "Running, abort."
		exit 0
	fi
fi

# system is not building, run update
git fetch $TEST_GIT_REMOTENAME
git diff $TEST_GIT_REMOTENAME/$TEST_GIT_BRANCHNAME --exit-code
RETVAL=$?
# if the diff value is non-zero kill the process and update
if [ ! $RETVAL -eq 0 ]
then
	echo -e "\0033[34mFetching latest build system version\0033[0m\n"
	# end the system
	pkill -f 'ruby build.rb'
	# end any screen session that might be hosting it
	screen -S $SCREEN_SESSION -X quit

	git pull $TEST_GIT_REMOTENAME $TEST_GIT_BRANCHNAME || exit 1
fi

if [ -z "$(pgrep ruby)" ]
then
	# start a new screen session called hans-ci
	screen -dmS $SCREEN_SESSION
	# Issue the ./run.sh command inside that session
	screen -S $SCREEN_SESSION -p 0 -X stuff $'./run.sh\n'
	# Mail a note
	echo "Test system updated successfully." | mail -s "PX4 HW Test System Updated" lorenz@px4.io -- -f autotest@px4.io
	echo "Test system updated successfully." | mail -s "PX4 HW Test System Updated" hans@px4.io -- -f autotest@px4.io
fi
