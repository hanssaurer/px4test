##Hardware-Test CI - Outline

[The fundamental issue is communication, not documentation!] (http://www.agilemodeling.com/essays/agileDocumentation.htm#ModelsDocumentsSourceCode)

Goal: Test a contribution on px4 Hardware

##Prerequisits

Postfix mailserver must be started and some environment variables must be set
see settings/constants

WebHook set on repository to be tested.

Trigger:
- Pull Request
- Push
- other modifications for ? purpose

Persistent WebHook: http://[ip or host]:4567/payload

###Sequence Outline:

On post\payload do
    
    case event
    when Pull Request
      grab pull request
      determine request reference data
      set environment vars
      set request pending
      call clone - build - hwtest
    when Push
      determine request reference data
      set environment vars
      set request pending
      call clone - build - hwtest
    else
      notify and ignore

###Clone Commands

    git clone --depth 500 #{html_url}.git --branch #{branch} –single-branch
    git submodule init
    git submodule update
    (git submodule status)
    
Additional command when Pull Request
    git remote add base_repo #{base_repo}.git
    git fetch base_repo
    git merge base_repo/#{base_branch} -m 'Merged #{base_repo}/#{base_branch} into test branch'


###Build Commands

    BOARDS="px4fmu-v2 px4io-v2" make archives
    make -j8 px4fmu-v2_test

###Hardware Test Command(s)

    Tools/px_uploader.py --port /dev/tty.usbmodem1 Images/px4fmu-v2_test.px4
    
Grab putput of serial port and scan output for error messages
(failed = testResult.include? "TEST FAILED"  or testResult.include? "failed")

Send test output by mail
Log activity in file (in the long run in database)


Set status of commit via Octokit
client.create_status(pr['base']['repo']['full_name'], pr['head']['sha'], 'success')

###Locking/Unlocking Measures

???

###Settings / Constants
In file config.txt

export GITTOKEN=[GITHUBTOKEN]
export PX4FORK=[FORK, use "PX4" as default]
NSH serial port, depends on HW setup
export NSHPORT=/dev/tty.usbmodemDDD5D1D3
export MAILSENDER=yourname@yourserver


###Mailserver Setup
In File: /etc/postfix/main.cf

smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = static:web354p3:px4SMTP2014Incoming_
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = may
smtp_use_tls = yes
header_size_limit = 4096000
relayhost = login-105.hoststar.ch:587

My differing settings (yet to be adjusted)

myhostname = www.hosting-agency.de
smtpd_sender_restrictions = permit_inet_interfaces
relayhost = smtp.hosting-agency.de
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous


git commands to stay up to date with forked repo

Commands to execute one time
git remote add upstream https://github.com/PX4/Firmware.git
git checkout master
git submodule init

Commands to execute on each time
git pull upstream master
git submodule update
git push origin master

