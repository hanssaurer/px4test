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
sudo apt-get install libopencv-highgui-dev
```

Install the Ruby dependencies using gem:

```
sudo gem install serialport sinatra json octokit thin specific_install aws-sdk
```

Install our custom rb_webcam gem and rmagick

```
sudo gem specific_install https://github.com/LorenzMeier/rb_webcam.git
```

Mac OS:
```
sudo gem specific_install https://github.com/rmagick/rmagick.git
```

Debian / Ubuntu:
```
sudo apt-get install ruby-rmagick
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
export MAILSENDER=autotest@px4.io
export AWS_ACCESS_KEY_ID=access_key_id
export AWS_SECRET_ACCESS_KEY=secret_access_key

```

The generation of Github tokens is explained on the Github help page:
https://help.github.com/articles/creating-an-access-token-for-command-line-use/

Also create a .hans.yml file in the local directory. In contrast to e.g. the .travis.yml this file should not be uploaded,
but is part of the local, host-specific configuration (and hence part of the .gitignore file).

NOTE: This is work in progress and only partially used

```YAML
# Build and autotest script for PX4 Firmware
# http://dronetest.io

hostname: 'zurich01'
location: 'Zurich'

github:
  fork: 'PX4'
  token: '[token]'

aws:
  key: '[aws key]'
  secret: '[aws secret]'

sponsor:
  name: 'Lorenz Meier'
  email: 'lorenz@px4.io'

# Connected test harnesses
setups:
- harness:
    name: 'FMUv2.4.5'
    bootloader: '/dev/usb/by-id/XXX'
    console: '/dev/usb/by-id/YYY'
    swd:
      fmu: '/dev/usb/by-id/BBB'
      io: '/dev/usb/by-id/AAA'
    branch: 'master'
    mode: 'soak'
    usb_power:
      hub: 1
      port: 2
    camera: 0

- harness:
    name: 'FMUvXXX'
    bootloader: '/dev/usb/by-id/XXX'
    console: '/dev/usb/by-id/YYY'
    swd:
      fmu: '/dev/usb/by-id/BBB'
      io: '/dev/usb/by-id/AAA'
    usb_power:
      hub: 1
      port: 3
    camera: 1
```


### Running the test environment  

Start the server

./run.sh

#### Auto Updating

Add watchdog.sh to a crontab entry. It will produce no outputs during normal operation and will update and restart the server if this GIT repository updates.

#### Standalone hardware tests

You can execute the hardware tests separately.
ruby hwtest.rb

