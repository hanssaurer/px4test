**Hardware-Test CI - Outline

[The fundamental issue is communication, not documentation!] (http://www.agilemodeling.com/essays/agileDocumentation.htm#ModelsDocumentsSourceCode)

Goal: Test a contribution on px4 Hardware

***Sequence Outline:

WebHook set on repository to be tested.

Trigger:
- Pull Request
- Push
- other modifications for ? purpose

Persistent WebHook: http://[ip or host]:4567/payload


Server calls px4clone.rb in subprocess
with branch and html_url as parameters

px4clone.rb - Clone
while lockfile exists and is not stale wait

    git clone --depth 500 #{html_url}.git --branch #{branch} –single-branch
    git submodule init
    git submodule update
    git submodule status

Executes px4make.rb (exec) and exits, staying in the subprocess

px4make.rb - Build

make distclean
make archives
make -j6 px4fmu-v2_test"

Executes hwtest.rb (exec) and exits, staying in the subprocess

hwtest.rb  - Test

make upload px4fmu-v2_test

Scan test output for errors
(failed = testResult.include? "TEST FAILED"  or testResult.include? "failed")
?Analyse and store detailed test results

- Publish Test Results


Set status of PR via Octokit
client.create_status(pr['base']['repo']['full_name'], pr['head']['sha'], 'success')

?Create comment on commit (push) – Has no status


Send test output by mail
?Post state of PR on Website


Settings / Constants

export GITTOKEN=[GITHUBTOKEN]
export PX4FORK=[FORK, use "PX4" as default]
# NSH serial port, depends on HW setup
export NSHPORT=/dev/tty.usbmodemDDD5D1D3
export MAILSENDER=	yourname@yourserver



