#!/usr/bin/env ruby
require_relative "../bucket"
require "test/unit"
require 'fileutils'

class TestBucket < Test::Unit::TestCase
 
  def test_bucket

    $aws_key = ENV['AWS_ACCESS_KEY_ID']
    $aws_secret = ENV['AWS_SECRET_ACCESS_KEY']

    puts("\n")

    bucket_name = 'results.dronetest.io'
    host = 'test01'
    file_name = 'localtest.txt'

    # Claim dir
    puts "Claiming directory"
    claimed_dir = results_claim_directory(bucket_name, host, $aws_key, $aws_secret)

    puts "New dir name: " + claimed_dir + "\n"

    # Write test file
    File.open(file_name, 'w') {|f| f.write(Time.now.strftime("%d/%m/%Y %H:%M")) }

    upload_result = results_upload(bucket_name, file_name, "%s/%s" % [claimed_dir, file_name], $aws_key, $aws_secret)

    # Cleanup
    FileUtils.rm_rf(file_name);

    assert_equal(true, upload_result, "Upload test failed")
  end
 
end
