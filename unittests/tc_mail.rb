#!/usr/bin/env ruby
require_relative "../ci_utils"
require "test/unit"

class TestBucket < Test::Unit::TestCase
 
  def test_mail

    puts("\n")

    puts("Sending email")

    srcdir = "abcd"
    branch = "master"
    url = "http://github.com/PX4/Firmware.git"
    full_repo_name = "PX4/Firmware"
    sha = "12345"
    results_url = "http://results.dronetest.io/zurich01/35/index.html"

    # Send success
    make_mmail "Lorenz Meier", "lm@inf.ethz.ch", "autotest@px4.io", "This is the detailed results log\n2nd line", true, srcdir, branch, url, full_repo_name, sha, results_url
    # Send failure
    make_mmail "Lorenz Meier", "lm@inf.ethz.ch", "autotest@px4.io", "This is the detailed results log\n2nd line", false, srcdir, branch, url, full_repo_name, sha, results_url
    # XXX mail function needs to return a value which should be checked below
    # assert_equal(0, ret, "HW upload test failed")
  end
 
end
