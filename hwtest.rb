#Simple Ruby program to read from a Serialport
#using the SerialPort gem
#(http://rubygems.org/gems/serialport)
 
require "serialport"
require 'net/smtp'

 
#params for serial port
port_str = "/dev/tty.usbmodemDDD5D1D3"  #last is 1 or 3
baud_rate = 57600
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE

#Other params
testcmd = "make upload px4fmu-v2_test"
$srcdir = "./testsrc"

#some variables need to be initialized
testResult = ""
command = ""
finished = false

def sendTestResult (testResult, success)

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
To: px4-contributor <someone@somewhere.org>
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
    smtp.send_message message, 'hans@saurer.name', 
                               'hans.saurer@t-online.de'
  end

end

 
sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
sp.read_timeout = 100

#Push enter to cause output of remnants
sp.write command + "\n"
input = sp.gets()
puts "Remnants:"
puts input

Dir.chdir($srcdir+"/Firmware") do
  result = `#{testcmd}`
  puts "Result: " + result 
  puts "---------- end of result------------"
end

sp = nil
sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
sp.read_timeout = 5000             #wait a little longer 

begin
  input = sp.gets()
  if input != nil and !input.empty?
    puts "<" + input
    testResult = testResult + input
    if testResult.index("nsh>") != nil
      finished = true
      puts "----------- Testresult------------"
      puts testResult
      sendTestResult testResult , false
      if testResult.index("TEST FAILED") != nil
        puts "TEST FAILED!"
      else
        puts "Test successful!"
      end  
    end  
  else
    puts "No input from serial port"
  end  
end until finished

sp.close                   
