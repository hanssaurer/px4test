## PX4 Test Suite for Continuous Delivery

*   Official Website: http://px4.io

## Installation

Install the dependencies using gem:

```
sudo gem install serialport sinatra json octokit
```

## Configuration

To run the system, a config file called config.txt should be created in this directory. The minimum content is this:

```
#!/bin/bash

# Configuration for PX4 test system

export GITTOKEN=<GITHUBTOKEN>

```

The generation of Github tokens is explained on the Github help page:
https://help.github.com/articles/creating-an-access-token-for-command-line-use/


##Initial 
###Separate scripts for Clone+Build and running tests

1. run build.rb
2. run runhwtest.rb

To run build set a WebHook to your server adress and port (4567)
and create an access token for your repository
and save it as ENV("GITTOKEN")
