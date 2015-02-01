#!/usr/bin/env ruby
require_relative "../cam"
require "test/unit"

class TestCam < Test::Unit::TestCase
 
  def test_cam

    puts("\n")

    cam_result = take_picture(".")
    puts "Leaving animated.gif for inspection"
    assert_equal(true, cam_result, "Camera picture test failed")
  end
 
end
