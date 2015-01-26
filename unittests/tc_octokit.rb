#!/usr/bin/env ruby
require 'octokit'
require "test/unit"

class TestBucket < Test::Unit::TestCase
 
  def test_octokit

    puts("\n")

    $ACCESS_TOKEN = ENV['GITTOKEN']
    puts "Access token: " + $ACCESS_TOKEN
    client = Octokit::Client.new(:access_token => $ACCESS_TOKEN)

    full_repo_name = 'PX4/Firmware'
    sha = '9cc94fcb2dde1a591c20e008ca59d1f876c2070a'

    commit = client.commit(full_repo_name, sha)

    puts "name: " + commit['commit']['author']['name']
    puts "email: " + commit['commit']['author']['email']
  end
 
end
