#!/usr/bin/env ruby

require 'yaml'

config = begin
  YAML.load(File.open(".hans.yml"))
rescue ArgumentError => e
  puts "Could not parse YAML: #{e.message}"
end

puts YAML.dump(config)

puts "Manually selected config pieces:"

puts "Github token: " + config['github']['token']
puts "AWS key: " + config['aws']['key']
