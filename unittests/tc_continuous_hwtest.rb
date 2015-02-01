#!/usr/bin/env ruby
require_relative '../build'
require 'test/unit'
require 'scanf'

class TestContinuousHWTest < Test::Unit::TestCase

  def test_parse_output

    puts "\n"

    testdata = "uorb_latency: mean:  22.9000
[MS5611_SPI] on SPI bus 4 at 2
[MS5611_SPI] on SPI bus 1 at 3
[MPU6000] on SPI bus 1 at 4
[LSM303D] on SPI bus 1 at 2
[L3GD20] on SPI bus 1 at 1"


    # This array holds the string to parse, the expected numbers
    # and the deviation in +- around the number allowed
    checks = [
                     [ {'str' => "[MS5611_SPI] on SPI bus %d at %d" }, {'expected' => [4, 2] }, {'margin' => [0, 0] }],

                    ]

    failed = []

    testdata.each_line do |line|

      checks.each do |check|
        puts line
        puts check
        #puts check['str'].toString
        exit
        numbers = line.scanf(check['str'])

        if (numbers.nil?)
          failed[check['str']] = "Not found"
          continue;
        end

        values_failed = false;
        failstr = ""

        for index in 0 ... numbers.size
          if (fabs(numbers[index] - check['expected'][index]) > check['margin'])
            puts "Failed: #{check['str']}"
            values_failed = true;
          end
        end

        if values_failed
          failed[check['str']] = "Values out of bounds: #{failstr}"
        end
      end
    end

  end
 
  def test_continuous

    puts("\n")

    puts("This test requires the Firmware directory to be checked out locally.")

    #ret = make_hwtest(nil, "../Firmware", "master", "http://github.com/PX4/Firmware", "PX4/Firmware", "0000")
    #assert_equal(0, ret, "HW upload test failed")
  end
 
end
