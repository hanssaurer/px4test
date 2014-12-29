#Simple Ruby program to read from a Serialport
#using the SerialPort gem
#(http://rubygems.org/gems/serialport)
 
require "serialport"
 
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
 


sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
sp.read_timeout = 100


puts "Hello - Enter command - (q)uit to end /'make' to run test"

#Push enter to cause prompt
sp.write command + "\n"

begin
  #print ("<")
  input = sp.gets()
  #input = sp.getc
  if input != nil and !input.empty?
    puts "<" + input
    testResult = testResult + input
  	#input.force_encoding("utf-8")
    #input.each_codepoint {|c| print c, ' ' }
    #printf("|%c", input.scrub("x"))
    if command == "make" and testResult.index("nsh>") != nil
      puts "----------- Testresult------------"
      puts testResult
      if testResult.index("TEST FAILED") != nil
        puts "TEST FAILED!"
      else
        puts "Test successful!"
      end  
      command = "q"                       #quit grafecul
    end  
  else
    puts ">"
    command = gets.chomp
    if command == "make"
      Dir.chdir($srcdir+"/Firmware") do
        result = `#{testcmd}`
        puts "Result: " + result 
        puts "---------- end of result------------"
      end  
      sp = nil
      sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
      sp.read_timeout = 5000             #wait a little longer 
      testResult = ""
    elsif command != "q"
      sp.write command + "\n"
    end  
  end  
end until command == "q" 

sp.close                   
