#!/usr/bin/env ruby
require_relative "../build"
require "test/unit"

class TestBucket < Test::Unit::TestCase
 
  def test_cam

    puts("\n")

    puts("This test requires the Firmware directory to be checked out locally.")

    ret = make_hwtest(nil, ".", "master", "http://github.com/PX4/Firmware", "PX4/Firmware", "0000")
    assert_equal(0, ret, "HW upload test failed")
  end
 
end
