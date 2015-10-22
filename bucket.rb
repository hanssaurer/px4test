
require 'rubygems'
require 'aws-sdk'
require 'fileutils'

def results_claim_directory(bucket_name, host, aws_key, aws_secret)
  # Get an instance of the S3 interface.
  s3 = Aws::S3::Resource.new(region: 'us-east-1', access_key_id: aws_key, secret_access_key: aws_secret)
  bucket = s3.bucket(bucket_name)

  if !bucket.exists?
    puts 'Bucket ' + bucket_name + ' does not exit!'
    return nil
  end

  s3_objects = bucket.objects(prefix: host) #.collect(&:key)

  largest = 0

  # This is terribly inefficient with the new AWS SDK
  # this needs to be done so it scales with a couple of
  # thousand runs.
  s3_objects.each do |obj|
    obj.key.slice! host + "/"
    s3_number = obj.key.split("/")[0].to_i

    if (s3_number > largest)
      largest = s3_number
    end
  end

  new_folder_index = largest + 1

  s3_new_key = sprintf("%s/%d", host, new_folder_index)

  claimed_file = '.claimed'
  FileUtils.touch(claimed_file)
  obj = bucket.object("%s/%s" % [s3_new_key, claimed_file])
  #obj.put(:body => claimed_file, :acl => "public-read")
  data = File.open claimed_file
  obj.upload_file(data, :acl => "public-read")
  FileUtils.rm_rf(claimed_file);

  return s3_new_key
end

def results_upload(bucket_name, local_file, results_file, aws_key, aws_secret)

  # Get an instance of the S3 interface.
  s3 = Aws::S3::Resource.new(region: 'us-east-1', access_key_id: aws_key, secret_access_key: aws_secret)
  bucket = s3.bucket(bucket_name)

  if !bucket.exists?
    puts 'Bucket ' + bucket_name + ' does not exit!'
    return false
  end

  # Upload a file.
  #key = File.basename(results_file)
  obj = bucket.object(results_file)
  #obj.put(:body => local_file)
  data = File.open local_file
  obj.upload_file(data, :acl => "public-read")
  puts "Uploading file #{local_file} to #{results_file} in bucket #{bucket_name}."
  puts "Link: http://#{bucket_name}/#{results_file}"
  return true
end
