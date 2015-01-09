require 'sinatra'
require 'json'
require 'octokit'
require 'open3'


#You can write Visual-Basic in any language!

set :bind, '0.0.0.0'
set :environment, :production
# XXX webrick has issues in recent versions accepting non-localhost transfers
set :server, :thin
set :port, 4567

$srcdir = "./default_testsrc"            #From some kind of config - later

$ACCESS_TOKEN = ENV['GITTOKEN']
fork = ENV['PX4FORK']

def do_work (command)

  Open3.popen2e(command) do |stdin, stdout_err, wait_thr|

    while line = stdout_err.gets
      puts "OUT>" + line
    end
    exit_status = wait_thr.value
    unless exit_status.success?
      abort "The command #{command} failed!"
    end
  end  
end  

    
def do_clone (branch, html_url)
    puts "do_clone: " + branch
    system 'mkdir', '-p', $srcdir
    Dir.chdir($srcdir) do
        #git clone <url> --branch <branch> --single-branch [<folder>]
        #result = `git clone --depth 500 #{html_url}.git --branch #{branch} --single-branch `
        #puts result
        do_work "git clone --depth 500 #{html_url}.git --branch #{branch} --single-branch"
        Dir.chdir("./Firmware") do
            #result = `git submodule init && git submodule update`
            #puts result
            do_work "git submodule init && git submodule update"
        end
    end
end    
    
def do_build ()
    puts "Starting build"
    Dir.chdir($srcdir+"/Firmware") do
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
        do_work  "git submodule init"
        do_work  "git submodule update"
        do_work  "git submodule status"
        do_work  "make distclean"
        do_work  "make archives"
        do_work  "make -j6 px4fmu-v2_default"
        do_work  "make upload px4fmu-v2_test"
    end
end    

def set_PR_Status (prstatus)
    puts "Access token: " + $ACCESS_TOKEN
    client = Octokit::Client.new(:access_token => $ACCESS_TOKEN)
    #puts client.user.location
    #puts pr['base']['repo']['full_name']
    #puts pr['head']['sha']
    client.create_status(pr['base']['repo']['full_name'], pr['head']['sha'], prstatus)
    puts "done!"
end    

def fork_hwtest
#Starts the hardware test in a subshell

pid = Process.fork
if pid.nil? then
  # In child
  #exec "pwd"
  exec "ruby hwtest.rb"
#  exec "ruby tstsub.rb"
else
  # In parent
  puts "PID: " + pid.to_s
  Process.detach(pid)
end

end    


# ---------- Routing ------------
get '/' do
  'Hello unknown'
end
post '/payload' do
  body = JSON.parse(request.body.read)
  puts "I got some JSON: " + JSON.pretty_generate(body)
  puts "Envelope: " + JSON.pretty_generate(request.env)

  github_event = request.env['HTTP_X_GITHUB_EVENT']
  puts "Event: " + github_event

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
    #do_clone  branch
    #do_build
    #set_PR_Status('success')
    #fork_hwtest
  when 'push'
    branch = body['ref']
    $srcdir = body['head_commit']['id']
    puts "Source directory: #{$srcdir}"
    ENV['srcdir'] = $srcdir
    #Set environment vars for sub processes
    ENV['pushername'] = body ['pusher']['name']
    ENV['pusheremail'] = body ['pusher']['email']
    a = branch.split('/')
    branch = a[a.count-1]           #last part is the bare branchname
    puts "Going to clone branch: " + branch + "from "+ body['repository']['html_url']
    #do_clone  branch, body['repository']['html_url']
    #do_build

    fork_hwtest

  else
    puts "unknown event"
  end
end
