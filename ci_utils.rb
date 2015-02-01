# Utilities to be called from CI test programs
#
# Not to be called as a program

require 'open3'
require 'erb'
require 'yaml'
require 'mail'

=begin
def wrap(s, width=78)
  s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
end
=end

def split_str(str, len = 40)
#from: www.ruby-forum.com/topic/87492
  fragment = /.{#{len}}/
  str.split(/(\s+)/).map! { |word|
    (/\s/ === word) ? word : word.gsub(fragment, '\0<wbr />')
  }.join
end

def generate_results_page (htmlfilename, contributor, email, sender, detailed_results, success, srcdir, branch, url, full_repo_name, sha, results_link, still_image_link)
  # Generate results page

  detailed_results = split_str(detailed_results,80)
  puts detailed_results
  if success
    one_line_feedback = 'The test succeeded'
  else
    one_line_feedback = 'The test failed'
  end

  commandlog = 'commandlog.txt'
  consolelog = 'consolelog.txt'

  s = File.read('results_page_text.erb')
  serb = ERB.new s
  styles = YAML.load_file('styles.yml')
  # Produce result
  s = serb.result(binding)

  # Save HTML document
  File.open(htmlfilename, 'w') {|f| f.write(s) }
end

def make_mmail (contributor, email, sender, detailed_results, success, srcdir, branch, url, full_repo_name, sha, results_link, still_image_link)
  # Create Confirmation email

  puts "Feedback email from ci_utils via mmail:"
  # Set up template data.
  cc1 = 'Hans Saurer <hans@px4.io>'
  cc2 = 'Lorenz Meier <lorenz@px4.io>'

  detailed_results = split_str(detailed_results,80)
  puts detailed_results
  if success
    one_line_feedback = 'The test succeeded'
    emailprefix = "SUCCESS"
  else
    one_line_feedback = 'The test failed'
    emailprefix = "FAIL"
  end

  s = File.read('mailtext.erb')
  serb = ERB.new s
  styles = YAML.load_file('styles.yml')
  # Produce result
  s = serb.result(binding)

  s = Mail::Encodings::QuotedPrintable::encode(s)
  # debug output puts "Encoded: #{s}"

  mail = Mail.new do
    from     "PX4 Hardware Test  <#{sender}>"
    to       "#{contributor} <#{email}>"
    cc       cc1 + "," + cc2
    subject  "#{emailprefix}: On-hardware test for #{branch} on #{full_repo_name} (#{sha})"

    puts "Sender: " + from.to_s
    
    html_part do
      content_type 'text/html; charset=UTF-8'
      content_transfer_encoding 'quoted-printable'
      body  s
    end
  end

  # Deliver email via sendmail, as default (SMTP)
  # requires valid SSL certificates for localhost
  mail.delivery_method :sendmail

  mail.deliver!
end


