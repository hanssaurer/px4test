
require 'rubygems'
require 'aws-sdk'
require 'fileutils'

def results_claim_directory(bucket_name, host)
  # Get an instance of the S3 interface.
  s3 = AWS::S3.new
  bucket = s3.buckets[bucket_name]

  if !bucket.exists?
    puts 'Bucket ' + bucket_name + ' does not exit!'
    return nil
  end

  s3_objects = bucket.objects.with_prefix(host).collect(&:key)

  largest = 0

  s3_objects.each do |s3_path|
    s3_path.slice! host + "/"
    s3_number = s3_path.split("/")[0].to_i

    if (s3_number > largest)
      largest = s3_number
    end
  end

  new_folder_index = largest + 1

  s3_new_key = sprintf("%s/%d", host, new_folder_index)

  claimed_file = '.claimed'
  FileUtils.touch(claimed_file)
  s3.buckets[bucket_name].objects["%s/%s" % [s3_new_key, claimed_file]].write(:file => claimed_file)
  FileUtils.rm_rf(claimed_file);

  return s3_new_key
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
