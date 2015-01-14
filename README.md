## PX4 Test Suite for Continuous Delivery

*   Official Website: http://px4.io

### Caveats

The current version of sinatra + webrick seems to hate external hosts and will go into timeout even if configured for RX address 0.0.0.0 and production. The server script is therefore hardcoded to the thin server.

### Installation

Install OS dependencies via the package manager:

Mac OS:
```
brew install opencv
```

Debian or Ubuntu:
```
sudo apt-get install opencvXXX
```

Install the Ruby dependencies using gem:

```
sudo gem install serialport sinatra json octokit thin specific_install aws-sdk
```

Install our custom rb_webcam gem and rmagick

```
sudo gem specific_install https://github.com/LorenzMeier/rb_webcam.git
sudo gem specific_install https://github.com/rmagick/rmagick.git
```

### Configuration

The configuration involves the local configuration and setting up a webhook in the repository.

#### Repository

Create a new webhook with a URL looking like the one below and replace [ip or host] with the appropriate hostname.

```
http://[ip or host]:4567/payload
```

#### Local

To run the system, a config file called config.txt should be created in this directory. The minimum content is this:

```
#!/bin/bash

# Configuration for PX4 test system

export GITTOKEN=[GITHUBTOKEN]
export PX4FORK=[FORK, use "PX4" as default]
# NSH serial port, depends on HW setup
export NSHPORT=/dev/tty.usbmodemDDD5D1D3
export AWS_ACCESS_KEY_ID=access_key_id
export AWS_SECRET_ACCESS_KEY=secret_access_key

```

The generation of Github tokens is explained on the Github help page:
https://help.github.com/articles/creating-an-access-token-for-command-line-use/


### Running the test environment  

Start the server

ruby build.rb

#### Auto Updating

Add watchdog.sh to a crontab entry. It will produce no outputs during normal operation and will update and restart the server if this GIT repository updates.

#### Standalone hardware tests

You can execute the hardware tests separately.
ruby hwtest.rb

