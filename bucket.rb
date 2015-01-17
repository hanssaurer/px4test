
require 'rubygems'
require 'aws-sdk'

def results_claim_directory(bucket_name, host)
  # Get an instance of the S3 interface.
  s3 = AWS::S3.new
  bucket = s3.buckets[bucket_name]

  if !bucket.exists?
    puts 'Bucket ' + bucket_name + ' does not exit!'
    return nil
  end

  filename = ''

  bucket.objects.each do |obj|
    filename = obj.key
    puts filename
  end

  return filename
end

def results_upload(bucket_name, local_file, results_file)

  # Get an instance of the S3 interface.
  s3 = AWS::S3.new
  bucket = s3.buckets[bucket_name]

  if !bucket.exists?
    puts 'Bucket ' + bucket_name + ' does not exit!'
    return false
  end

  # Upload a file.
  #key = File.basename(results_file)
  s3.buckets[bucket_name].objects[results_file].write(:file => local_file)
  puts "Uploading file #{local_file} to #{results_file} in bucket #{bucket_name}."
  puts "Link: http://#{bucket_name}/#{results_file}"
  return true
end
