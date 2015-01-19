# Utilities to be called from CI test programs
#
# Not to be called as a program

require 'open3'
require 'erb'
require 'yaml'
require 'mail'

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


def wrap(s, width=78)
  s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
end

def split_str(str, len = 40)
#from: www.ruby-forum.com/topic/87492
  fragment = /.{#{len}}/
  str.split(/(\s+)/).map! { |word|
    (/\s/ === word) ? word : word.gsub(fragment, '\0<wbr />')
  }.join
end


def make_mmail (detailed_results, success, pr, srcdir, branch, url, full_repo_name, sha)
#Create Confirmation email

puts "Feedback email from ci_utils via mmail:"
  # Set up template data.
  sender = ENV['MAILSENDER']
  contributor = ENV['pushername']
  email = ENV['pusheremail']
  cc1 = 'hans.saurer@t-online.de'
  cc2 = 'lm@qgroundcontrol.org'

  detailed_results = split_str(detailed_results,80)
  puts detailed_results
  s = File.read('mailtext.erb')
  serb = ERB.new s
  styles = YAML.load_file('styles.yml')
  # Produce result
  s = serb.result(binding)

  s = Mail::Encodings::QuotedPrintable::encode(s)
  puts "Encoded: #{s}"


mail = Mail.new do
  from     "PX4 Hardware Test  <#{sender}>"
  to       "#{contributor} <#{email}>"
  cc       cc1
  subject  'On-hardware test result for PX4/Firmware'
  
  html_part do
    content_type 'text/html; charset=UTF-8'
    content_transfer_encoding 'quoted-printable'
    body  s
  end
  #add_file :filename => 'TestResult.txt', :content => attachment
end

mail.deliver!

  #puts mail.to_s
  #return message
end


