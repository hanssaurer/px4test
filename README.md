## PX4 Test Suite for Continuous Delivery

*   Official Website: http://px4.io

### Caveats

The current version of sinatra + webrick seems to hate external hosts and will go into timeout even if configured for RX address 0.0.0.0 and production. The server script is therefore hardcoded to the thin server.

### Installation

Install the dependencies using gem:

```
sudo gem install serialport sinatra json octokit thin
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

```

The generation of Github tokens is explained on the Github help page:
https://help.github.com/articles/creating-an-access-token-for-command-line-use/


### Testing 

XXX Describe how to run tests

1. run build.rb
2. run runhwtest.rb

