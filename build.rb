require 'sinatra'
require 'json'
require 'octokit'
#require 'open3'
require 'fileutils'
require "serialport"
$LOAD_PATH << '.'
require 'ci_utils.rb'


require_relative "bucket"
require_relative "cam"

set :bind, '0.0.0.0'
set :environment, :production
# XXX webrick has issues in recent versions accepting non-localhost transfers
set :server, :thin
set :port, 4567

$aws_key = ENV['AWS_ACCESS_KEY_ID']
$aws_secret = ENV['AWS_SECRET_ACCESS_KEY']

$nshport = ENV['NSHPORT']
$ACCESS_TOKEN = ENV['GITTOKEN']
$logdir = './'
$commandlog = 'commandlog.txt'
$consolelog = 'consolelog.txt'
$bucket_name = 'results.dronetest.io'
$host = 'zurich01'
$results_url = ""
$continuous_branch = nil
$clonedir = "Firmware"
$hardware_test_timeout = 60

$lf = '.lockfile'

def do_lock(board)
  # XXX put this into a function and check for a free worker
  # also requires to name directories after the free worker
  while File.file?(board)
    # Check if the lock file is really old, if yes, take our chances and wipe it
    if ((Time.now - File.stat(board).mtime).to_i > (60 * 10)) then
      do_unlock('boardname')
      break
    end

    # Keep waiting as long as the lock file exists
    sleep(1)
  end

  # This is the critical section - we might want to lock it
  # using a 2nd file, or something smarter and proper.
  # XXX for now, we just bet on timing - yay!
  FileUtils.touch($lf)
end

def do_unlock(board)
  # We're done - delete lock file
  FileUtils.rm_rf(board)
end

def do_work (command, error_message, work_dir)

  Open3.popen2e(command, :chdir=>"#{work_dir}") do |stdin, stdout_err, wait_thr|

  logfile = File.open($logdir + $commandlog, 'a')

    while line = stdout_err.gets
      puts "OUT> " + line
      logfile << line
    end
    exit_status = wait_thr.value
    unless exit_status.success?
      do_unlock($lf)
      set_PR_Status $full_repo_name, $sha, 'failure', error_message
      failmsg = "The command #{command} failed!"
      puts failmsg
      logfile << failmsg
      logfile.close
      # Do not run through the standard exit handlers
      exit!(1)
    end
  end
end

def do_clone (srcdir, branch, html_url)
    puts "do_clone: " + branch
    system 'mkdir', '-p', srcdir
    Dir.chdir(srcdir) do
        #git clone <url> --branch <branch> --single-branch [<folder>]
        #result = `git clone --depth 500 #{html_url}.git --branch #{branch} --single-branch `
        #puts result
        do_work "git clone --depth 500 #{html_url}.git --branch #{branch} --single-branch #{$clonedir}", "Cloning repo failed.", "."
        Dir.chdir("#{$clonedir}") do
            #result = `git submodule init && git submodule update`
            #puts result
            do_work "git submodule init", "GIT submodule init failed", "."
            do_work "git submodule update --recursive", "GIT submodule update failed", "."
        end
    end
end

def do_master_merge (srcdir, base_repo, base_branch)
    puts "do_merge of #{base_repo}/#{base_branch}"
    Dir.chdir(File.join(srcdir, "#{$clonedir}")) do
        do_work "git remote add base_repo #{base_repo}.git", "GIT adding upstream failed", "."
        do_work "git fetch base_repo", "GIT fetching upstream failed", "."
        do_work "git merge base_repo/#{base_branch} -m 'Merged #{base_repo}/#{base_branch} into test branch'", "Failed merging #{base_repo}/#{base_branch}", "."
    end
end
    
def do_build (srcdir)
    puts "Starting build"
    Dir.chdir(File.join(srcdir, "#{$clonedir}")) {
        system 'mkdir', '-p', 'build_px4fmu-v2_default'
        do_work "cmake ..", "cmake run", "build_px4fmu-v2_default"
        do_work "make", "make px4fmu-v2_default failed", "build_px4fmu-v2_default"
        # do_work  "make px4fmu-v2_test", "make px4fmu-v2_test failed", File.join(srcdir, "#{$clonedir}")
    }
end    

def openserialport (timeout)
  #Open serial port - safe
  #params for serial port

  port_str = $nshport
  baud_rate = 57600
  data_bits = 8
  stop_bits = 1
  parity = SerialPort::NONE

  begin
    sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
    puts "Opening port: " + port_str
    sp.read_timeout = timeout
    return sp
  rescue Errno::ENOENT
    puts "Serial port not available! Please (re)connect!"
    sleep(1)
    retry
  end 
end


def make_hwtest (pushername, pusheremail, pr, srcdir, branch, url, full_repo_name, sha, results_link, results_image_link, hw_timeout)
  # Execute hardware test
  sender = ENV['MAILSENDER']
  testcmd = "Tools/px_uploader.py --port \"/dev/serial/by-id/usb-3D_Robotics*,/dev/tty.usbmodem1\" build_px4fmu-v2_default/src/firmware/nuttx/nuttx-px4fmu-v2-default.px4"

  #some variables need to be initialized
  testResult = ""
  finished = false

  puts "----------------- Hardware-Test running ----------------"
  sp = openserialport 100

  #Push enter to cause output of remnants
  sp.write "\n"
  input = sp.gets()
  puts "Remnants:"
  puts input
  sp.close

  Dir.chdir(srcdir+"/Firmware") do
    #puts "Call: " + testcmd
    #result = `#{testcmd}`
    puts "---------------command output---------------"
    do_work testcmd, "Firmware upload failed", File.join(srcdir, "#{$clonedir}")
    puts "---------- end of command output------------"
  end

  # Total test timeout in seconds
  test_timeout_s = hw_timeout;

  # Wait 0.5 s for new data
  read_timeout_ms = 500

  sp = openserialport read_timeout_ms

  test_passed = false

  # XXX prepend each line with a time marker
  # so we know if output comes in with huge delays

  test_start_time = Time.now

  begin
    begin
      input = sp.gets()
    rescue Errno::ENXIO  
      puts "Serial port not available! Please connect"
      sleep(1)
      sp = openserialport read_timeout_ms
      retry
    end
    if !input.nil?
    #if input != nil and !input.empty?
      testResult = testResult + input
      if testResult.include? "NuttShell"
        finished = true
        puts "---------------- Testresult----------------"
        #puts testResult

        # Write test results to console log file
        File.open($logdir + $consolelog, 'w') {|f| f.write(testResult) }

        if (testResult.include? "TEST FAILED") || (testResult.include? "Tests FAILED")
          puts "TEST FAILED!"
          test_passed = false
        else
          test_passed = true
          puts "Test successful!"
        end

      end  
    elsif ((test_timeout_s > 0) && ((Time.now() - test_start_time) > test_timeout_s))
      finished = true
      File.open($logdir + $consolelog, 'w') {|f| f.write(testResult + "\nSERIAL READ TIMEOUT!\n") }
      puts "Serial port timeout"
    end  
  end until finished
  
  # Send out email
  make_mmail pushername, pusheremail, sender, testResult, test_passed, srcdir, branch, url, full_repo_name, sha, results_link, results_image_link
  # Prepare result for upload
  generate_results_page 'index.html', pushername, pusheremail, sender, testResult, test_passed, srcdir, branch, url, full_repo_name, sha, results_link, results_image_link

  sp.close

  # Provide exit status
  if (test_passed)
    return 0
  else
    return 1
  end

end


def set_PR_Status (repo, sha, prstatus, description)

  puts "Access token: " + $ACCESS_TOKEN
  client = Octokit::Client.new(:access_token => $ACCESS_TOKEN)
  # XXX replace the URL below with the web server status details URL
  options = {
    "state" => prstatus,
    "target_url" => $results_url,
    "description" => description,
    "context" => "continuous-integration/hans-ci"
  };
  puts "Setting commit status on repo: " + repo + " sha: " + sha + " to: " + prstatus + " description: " + description
  res = client.create_status(repo, sha, prstatus, options)
  puts res
end    

def fork_hwtest (continuous_branch, pushername, pusheremail, pr, srcdir, branch, url, full_repo_name, sha)
#Starts the hardware test in a subshell

pid = Process.fork
if pid.nil? then

  # Lock this board for operations
  do_lock($lf)
  # Clean up any mess left behind by a previous potential fail
  FileUtils.rm_rf(srcdir)
  FileUtils.mkdir(srcdir);
  FileUtils.touch($logdir + $consolelog)

  # In child

  s3_dirname = results_claim_directory($bucket_name, $host, $aws_key, $aws_secret)

  $results_url = sprintf("http://%s/%s/index.html", $bucket_name, s3_dirname);
  results_still = sprintf("http://%s/%s/still.jpg", $bucket_name, s3_dirname);

  # Set relevant global variables for PR status
  $full_repo_name = full_repo_name
  $sha = sha

  tgit_start = Time.now
  do_clone srcdir, branch, url
  if !pr.nil?
    do_master_merge srcdir, pr['base']['repo']['html_url'], pr['base']['ref']
  end
  tgit_duration = Time.now - tgit_start
  tbuild_start = Time.now
  do_build srcdir
  tbuild_duration = Time.now - tbuild_start

  # Run the hardware test
  hw_timeout = $hardware_test_timeout;

  # If the continuous integration branch name
  # is set, indicate that the HW test should
  # never actually time out
  if (!continuous_branch.nil?)
    hw_timeout = 0;
  end

  thw_start = Time.now
  result = make_hwtest pushername, pusheremail, pr, srcdir, branch, url, full_repo_name, sha, $results_url, results_still, hw_timeout
  thw_duration = Time.now - thw_start

  # Take webcam image
  take_picture(".")

  # Upload still JPEG
  results_upload($bucket_name, 'still.jpg', '%s/%s' % [s3_dirname, 'still.jpg'], $aws_key, $aws_secret)
  FileUtils.rm_rf('still.jpg')

  timingstr = sprintf("%4.2fs", tgit_duration + tbuild_duration + thw_duration)
  puts "HW TEST RESULT:" + result.to_s
  if (result == 0) then
    set_PR_Status full_repo_name, sha, 'success', 'Pixhawk HW test passed: ' + timingstr
  else
    set_PR_Status full_repo_name, sha, 'failure', 'Pixhawk HW test FAILED: ' + timingstr
  end

  # Logfile
  results_upload($bucket_name, $logdir + $commandlog, '%s/%s' % [s3_dirname, 'commandlog.txt'], $aws_key, $aws_secret)
  FileUtils.rm_rf($commandlog)
  results_upload($bucket_name, $logdir + $consolelog, '%s/%s' % [s3_dirname, 'consolelog.txt'], $aws_key, $aws_secret)
  FileUtils.rm_rf($logdir + $consolelog)
  # GIF
  results_upload($bucket_name, 'animated.gif', '%s/%s' % [s3_dirname, 'animated.gif'], $aws_key, $aws_secret)
  FileUtils.rm_rf('animated.gif')

  # Index page
  results_upload($bucket_name, 'index.html', '%s/%s' % [s3_dirname, 'index.html'], $aws_key, $aws_secret)
  FileUtils.rm_rf('index.html')

  # Clean up by deleting the work directory
  FileUtils.rm_rf(srcdir)
  # Unlock this board
  do_unlock($lf)
  exit! 0

else
  # In parent
  puts "Worker PID: " + pid.to_s
  Process.detach(pid)
end

end    


# ---------- Routing ------------
get '/' do
  "Hello unknown"
end
get '/payload' do
  "This URL is intended to be used with POST, not GET"
end
post '/payload' do
  body = JSON.parse(request.body.read)
  github_event = request.env['HTTP_X_GITHUB_EVENT']

  case github_event
  when 'ping'
        "Hello"    
  when 'pull_request'
  begin
    pr = body["pull_request"]
    number = body['number']
    puts pr['state']
    action = body['action']
    if (['opened', 'reopened'].include?(action))
      sha = pr['head']['sha']
      srcdir = sha
      $logdir = Dir.pwd + "/" + srcdir + "/"
      full_name = pr['base']['repo']['full_name']
      puts "Source directory: #{srcdir}"
      #Set environment vars for sub processes

      # Pull last commiter email for PR from GH
      client = Octokit::Client.new(:access_token => $ACCESS_TOKEN)
      commit = client.commit(full_name, sha)
      pushername = commit['commit']['author']['name']
      pusheremail = commit['commit']['author']['email']
      branch = pr['head']['ref']
      url = pr['head']['repo']['html_url']
      puts "Adding to queue: Pull request: #{number} " + branch + " from "+ url
      set_PR_Status full_name, sha, 'pending', 'Running test on Pixhawk hardware..'
      fork_hwtest nil, pushername, pusheremail, pr, srcdir, branch, url, full_name, sha
      puts 'Pull request event queued for testing.'
    else
      puts 'Ignoring closing of pull request #' + String(number)
    end
  end
   
  when 'push'
    branch = body['ref']

    if !(body['head_commit'].nil?) && body['head_commit'] != 'null'
      sha = body['head_commit']['id']
      srcdir = sha
      $logdir = Dir.pwd + "/" + srcdir + "/";
      puts "Source directory: #{srcdir}"
      #Set environment vars for sub processes
      pushername = body ['pusher']['name']
      pusheremail = body ['pusher']['email']
      a = branch.split('/')
      branch = a[a.count-1]           #last part is the bare branchname
      puts "Adding to queue: Branch: " + branch + " from "+ body['repository']['html_url']
      full_name = body['repository']['full_name']
      puts "Full name: " + full_name
      set_PR_Status full_name, sha, 'pending', 'Running test on Pixhawk hardware..'
      fork_hwtest $continuous_branch, pushername, pusheremail, nil, srcdir, branch, body['repository']['html_url'], full_name, sha
      puts 'Push event queued for testing.'
    end
  when 'status'
    puts "Ignoring GH status event"
  when 'fork'
    puts 'Ignoring GH fork repo event'
  when 'delete'
    puts 'Ignoring GH delete branch event'
  when 'issue_comment'
    puts 'Ignoring comments'
  when 'issues'
    puts 'Ignoring issues'
  when 'pull_request_review_comment'
    puts 'Ignoring review comment'
  when 'started'
    puts 'Ignoring started request'

  else
    puts "Unhandled request:"
    puts "Envelope: " + JSON.pretty_generate(request.env)
    puts "JSON: " + JSON.pretty_generate(body)
    puts "Unknown Event: " + github_event

  end
end
