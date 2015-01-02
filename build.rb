require 'sinatra'
require 'json'
require 'octokit'

#You can write Visual-Basic in any language!

set :bind, '0.0.0.0'
set :environment, :production
# XXX webrick has issues in recent versions accepting non-localhost transfers
set :server, :thin
set :port, 4567

$srcdir = "./testsrc"            #From some kind of config - later

$ACCESS_TOKEN = ENV['GITTOKEN']
fork = ENV['PX4FORK']
    
def do_clone (branch)
    puts "do_clone: " + branch
    system 'mkdir', '-p', $srcdir
    Dir.chdir($srcdir) do
        #git clone <url> --branch <branch> --single-branch [<folder>]
        result = `git clone https://github.com/hanssaurer/Firmware.git --branch #{branch} --single-branch `
        puts result
        Dir.chdir("./Firmware") do
            result = `git clone https://github.com/PX4/NuttX`
            puts result
        end
    end
end    
    
def do_build ()
    puts "build"
    Dir.chdir($srcdir+"/Firmware") do
        result = `git submodule init`
        puts result
        result = `git submodule update`
        puts result
        result = `git submodule status`
        puts result
        result = `make distclean`
        puts result
        result = `make archives`
        puts result
        result = `make`
        puts result
        result = `make upload px4fmu-v2_default`
        puts result
    end
end    

def set_PR_Status (prstatus)
    puts "Access token: " + $ACCESS_TOKEN
    client = Octokit::Client.new(:access_token => $ACCESS_TOKEN)
    #puts client.user.location
    #puts pr['base']['repo']['full_name']
    #puts pr['head']['sha']
    client.create_status(pr['base']['repo']['full_name'], pr['head']['sha'], prstatus)
    puts "fertig!"
end    


# ---------- Routing ------------
get '/' do
  'Hallo unbekannt'
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
        #puts body.keys
        pr = body["pull_request"]
        branch = pr["base"]["ref"]
        a = branch.split('/')
        branch = a[a.count-1]           #last part is the bare branchname
        puts "Going to clone branch: " + branch
        do_clone  branch
        do_build
        set_PR_Status('success')
    when 'push'
        branch = body['ref']
        a = branch.split('/')
        branch = a[a.count-1]           #last part is the bare branchname
        puts "Going to clone branch: " + branch
        do_clone  branch
        do_build

#Hot - call testrun in child process and detach
pid = Process.fork
if pid.nil? then
  # In child
  exec "ruby hwtest.rb"
else
  # In parent
  Process.detach(pid)
end




    else
        puts "unknown event"
    end
end
