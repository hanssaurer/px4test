#Simple Ruby program to read from a Serialport
#using the SerialPort gem
#(http://rubygems.org/gems/serialport)
 
require "serialport"
require 'net/smtp'
require 'open3'

puts "----------------- Hardware-Test running ----------------"
 

#Other params
#testcmd = "make upload px4fmu-v2_test"
testcmd = "Tools/px_uploader.py --port /dev/tty.usbmodem1 Images/px4fmu-v2_test.px4"
$srcdir = ENV['srcdir']
puts "Source directory: " + $srcdir

#some variables need to be initialized
testResult = ""
finished = false

def sendTestResult (testResult, success)

  #Environment specific! Must be added to config
  sender = ENV['MAILSENDER']

  contributor = ENV['pushername']
  email = ENV['pusheremail']
  #???Copy to some control authority
  cc1 = 'hans.saurer@t-online.de'
  cc2 = 'lm@qgroundcontrol.org'
  #For standalone testing
  if email.nil? then email = cc1 end


  filename = "TestResult.txt"
  marker = "px4-postfix-smtpmail*******"

  if success
    body = "The test was successful!."
  else
    body = "The test FAILED!"
  end 
  body = body + "\nFor details see attachment.\n\n"
  body = body + "This is a automatically generated mail. Do not reply to the sender."

  attachcontent = testResult

#Mail Parts
#From will be used for reply. To is just description
#Recipients not listed as To or CC will be BCC
#Heredoc breakds indentation
mpart1 = <<EOF
From: px4tester <autotest@px4.io>
To: #{contributor} #{email}
CC: Hans Saurer <hans@saurer.name>
Subject: SMTP e-mail test
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}
EOF

mpart2 =<<EOF
Content-Transfer-Encoding: 7bit
Content-Type: text/plain;
  charset=us-ascii

#{body}
--#{marker}
EOF

# Define the attachment section
mpart3 =<<EOF
Content-Disposition: attachment;
  filename="#{filename}"
Content-Type: text/plain;
  name=\"#{filename}\"
Content-Transfer-Encoding: quoted-printable

#{attachcontent}
--#{marker}--
EOF

  message = mpart1 + mpart2 + mpart3

  #Params: "message-text, sender, recipient, recipient..."
  Net::SMTP.start('localhost') do |smtp|
    #smtp.send_message message, sender, email, cc1
    smtp.send_message message, sender, cc2, cc1
                               
  end

end

def openserialport (timeout)
  #Open serial port - safe
  #params for serial port

  port_str = "/dev/tty.usbmodemDDD5D1D3"  #last is 1 or 3
  baud_rate = 57600
  data_bits = 8
  stop_bits = 1
  parity = SerialPort::NONE

  begin
    sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
    sp.read_timeout = timeout
    return sp
  rescue Errno::ENOENT
    puts "Serial port not available! Please disconnect, wait 5 seconds and connect"
    sleep(1)
    retry
  end 
end

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

sp = openserialport 100

#Push enter to cause output of remnants
sp.write "\n"
input = sp.gets()
puts "Remnants:"
puts input
sp.close

Dir.chdir($srcdir+"/Firmware") do
  #puts "Call: " + testcmd
  #result = `#{testcmd}`
  puts "---------------command output---------------"
  do_work testcmd  
  puts "---------- end of command output------------"
end

sp = openserialport 5000
sleep(5)

begin
  begin
    input = sp.gets()
  rescue Errno::ENXIO  
    puts "Serial port not available! Please connect"
    sleep(1)
    sp = openserialport 5000
    retry
  end
  if !input.nil?
  #if input != nil and !input.empty?
    testResult = testResult + input
    if testResult.include? "NuttShell"
      finished = true
      puts "---------------- Testresult----------------"
      puts testResult
      if testResult.include? "TEST FAILED"  or testResult.include? "failed"
        puts "TEST FAILED!"
        sendTestResult testResult , false
      else
        puts "Test successful!"
      sendTestResult testResult , true
      end  
    end  
  else
    finished = true
    puts "No input from serial port"
  end  
end until finished

sp.close                   
