#!/usr/bin/env ruby

require 'rubygems'
require 'aws-sdk'

bucket_name = 'results.dronetest.io'
file_name = 'test.txt'

File.open(file_name, 'w') {|f| f.write(Time.now.strftime("%d/%m/%Y %H:%M")) }

# Get an instance of the S3 interface.
s3 = AWS::S3.new

# Upload a file.
key = File.basename(file_name)
s3.buckets[bucket_name].objects[key].write(:file => file_name)
puts "Uploading file #{file_name} to bucket #{bucket_name}."
