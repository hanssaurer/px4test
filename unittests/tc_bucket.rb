#!/usr/bin/env ruby
require_relative "../bucket"
require "test/unit"
require 'fileutils'

class TestBucket < Test::Unit::TestCase
 
  def test_bucket

    puts("\n")

    bucket_name = 'results.dronetest.io'
    host = 'test01'
    file_name = 'localtest.txt'
    test_count = '005'

    claimed_dir = "%s/%s" % [host, test_count]

    # Write test file
    File.open(file_name, 'w') {|f| f.write(Time.now.strftime("%d/%m/%Y %H:%M")) }

    upload_result = results_upload(bucket_name, file_name, "%s/%s" % [claimed_dir, file_name])

    # Cleanup
    FileUtils.rm_rf(file_name);

  # Claim dir
  #puts "Claiming directory"
  #dir = results_claim_directory(bucket_name, host)

  #puts = "New dir: " + dir + "\n"

    assert_equal(true, upload_result, "Upload test failed")
  end
 
end
