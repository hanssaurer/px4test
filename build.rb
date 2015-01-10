require 'sinatra'
require 'json'
require 'octokit'
require 'open3'
require 'fileutils'

#You can write Visual-Basic in any language!

set :bind, '0.0.0.0'
set :environment, :production
# XXX webrick has issues in recent versions accepting non-localhost transfers
set :server, :thin
set :port, 4567

$ACCESS_TOKEN = ENV['GITTOKEN']
fork = ENV['PX4FORK']

def do_work (command)

  Open3.popen2e(command) do |stdin, stdout_err, wait_thr|

    while line = stdout_err.gets
      puts "OUT> " + line
    end
    exit_status = wait_thr.value
    unless exit_status.success?
      abort "The command #{command} failed!"
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
        do_work "git clone --depth 500 #{html_url}.git --branch #{branch} --single-branch"
        Dir.chdir("Firmware") do
            #result = `git submodule init && git submodule update`
            #puts result
            do_work "git submodule init"
            do_work "git submodule update"
        end
    end
end

def do_master_merge (srcdir)
    puts "do_merge "
    Dir.chdir(srcdir + "/Firmware") do
        do_work "git remote add upstream https://github.com/PX4/Firmware.git"
        do_work "git pull upstream master"
    end
end
    
def do_build (srcdir)
    puts "Starting build"
    Dir.chdir(srcdir+"/Firmware") do
=begin        
        result = `git submodule init`
puts "********************************** git submodule init *******************************************"
        puts result
        result = `git submodule update`
puts "********************************** git submodule update *******************************************"
        puts result
        result = `git submodule status`
puts "********************************** git submodule status *******************************************"
        puts result
        result = `make distclean`
puts "********************************** make distclean *******************************************"
        puts result
        result = `make archives`
puts "********************************** make archives *******************************************"
        puts result
        result = `make -j6 px4fmu-v2_default`
puts "********************************** make -j6 px4fmu-v2_default *******************************************"
        puts result

puts "\n\n**********make upload px4fmu-v2_default aufgerufen************"
        result = `make upload px4fmu-v2_test`
        #result = `Tools/px_uploader.py --port /dev/tty.usbmodem1 Images/px4fmu-v2_default.px4`
puts "********************************** make upload px4fmu-v2_default *******************************************"
        puts result
=end    
        do_work  'BOARDS="px4fmu-v2 px4io-v2" make archives'
        do_work  "make -j8 px4fmu-v2_test"
    end
end    

def set_PR_Status (pr, prstatus)

  if !pr.nil?
    puts "Access token: " + $ACCESS_TOKEN
    client = Octokit::Client.new(:access_token => $ACCESS_TOKEN)
    #puts client.user.location
    #puts pr['base']['repo']['full_name']
    #puts pr['head']['sha']
    client.create_status(pr['base']['repo']['full_name'], pr['head']['sha'], prstatus)
    puts "Set PR status:" + prstatus
  end
end    

def fork_hwtest (pr, srcdir, branch, url)
#Starts the hardware test in a subshell

pid = Process.fork
if pid.nil? then
  # In child
  #exec "pwd"
  do_clone srcdir, branch, url
  if !pr.nil?
    do_master_merge srcdir
  end
  do_build srcdir
  system 'ruby hwtest.rb'
  puts "HW TEST RESULT:" + $?.exitstatus.to_s

  if ($?.exitstatus == 0) then
    set_PR_Status pr, 'success'
  else
    set_PR_Status pr, 'failed'
  end

  # Clean up by deleting the work directory
  FileUtils.rm_rf(srcdir)

#  exec "ruby tstsub.rb"
else
  # In parent
  puts "Worker PID: " + pid.to_s
  Process.detach(pid)
end

end    


# ---------- Routing ------------
get '/' do
  'Hello unknown'
end
post '/payload' do
  body = JSON.parse(request.body.read)
  github_event = request.env['HTTP_X_GITHUB_EVENT']

  case github_event
  when 'ping'
        "Hello"    
  when 'pull_request'
    pr = body["pull_request"]
    mydir = body['sha']
    puts "Source directory: #{mydir}"
    branch = pr["base"]["ref"]
    a = branch.split('/')
    branch = a[a.count-1]           #last part is the bare branchname
    puts "Pull Request! Going to clone branch: " + branch
    set_PR_Status pr, 'pending'
    fork_hwtest pr, srcdir, branch, body['repository']['html_url']
  when 'push'
    branch = body['ref']
    srcdir = body['head_commit']['id']
    puts "Source directory: #{$srcdir}"
    ENV['srcdir'] = srcdir
    #Set environment vars for sub processes
    ENV['pushername'] = body ['pusher']['name']
    ENV['pusheremail'] = body ['pusher']['email']
    a = branch.split('/')
    branch = a[a.count-1]           #last part is the bare branchname
    puts "Cloning branch: " + branch + "from "+ body['repository']['html_url']

    fork_hwtest nil, srcdir, branch, body['repository']['html_url']
  when 'status'
    puts "Ignoring GH status update"

  else
    puts "unknown event:"
    puts "I got some JSON: " + JSON.pretty_generate(body)
    puts "Envelope: " + JSON.pretty_generate(request.env)
    puts "Event: " + github_event

  end
end
