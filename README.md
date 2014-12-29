## PX4 Test Suite for Continuous Delivery

*   Official Website: http://px4.io

##Initial 
###Separate scripts for Clone+Build and running tests

1. run build.rb
2. run runhwtest.rb

To run build set a WebHook to your server adress and port (4567)
and create an access token for your repository
and save it as ENV("GITTOKEN")
https://help.github.com/articles/creating-an-access-token-for-command-line-use/