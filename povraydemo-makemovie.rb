# This demo shows how to use Amazon EC2 Spot Instances and Amazon SQS to
# generate the movie images for a fly-by of a Julia Set Island.

require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'pp'

# This file has my AWS access key and private key
config_file = File.join(File.dirname(__FILE__), "config.yml")

# IF CONFIG FILE DOESN'T EXIST, EXIT
unless File.exist?(config_file)
  puts <<END
To run the samples, put your credentials in config.yml as follows:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY

END
  exit 1
end

# LOAD CONFIG FILE
config = YAML.load(File.read(config_file))

# IF CONFIG FILE IS FORMATTED INCORRECTLY, EXIT
unless config.kind_of?(Hash)
  puts <<END
config.yml is formatted incorrectly.  Please use the following format:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY

END
  exit 1
end

# SET CONFIG SETTINGS
AWS.config(config)

# CREATING A BUCKET FOR THE FILES TO BE SAVED TO
s3 = AWS::S3.new(:s3_endpoint => "s3-us-west-2.amazonaws.com")
# create a bucket
bucket_name = "stephee-povraydemo"
b = s3.buckets[bucket_name]
# create the bucket if it doesn't exist
if not b.exists? then
  b = s3.buckets.create(bucket_name)
  puts "S3 bucket #{b.name} created in #{b.location_constraint}."
else
  puts "Using S3 bucket #{b.name} in #{b.location_constraint}."
end

# DOWNLOAD ALL MOVIE FRAMES
# This should be its own file

b.objects.each do |obj|
  s3_filename = obj.key
  if s3_filename.scan(/\w*.(\w*)/)[0][0] == "png"
    puts "Downloading #{s3_filename}..."
    File.open(s3_filename, 'w') do |file|
      obj.read do |chunk|
        file.write(chunk)
      end
    end
  end
end

puts "Rendering movie..."
movie_file_name = "JuliaIsleMovie.mp4"
`ffmpeg -qscale 5 -r 24 -b 64k -i frame%03d.png #{movie_file_name}`

puts "Uploading #{movie_file_name} to S3..."
# Upload Movie file
o = b.objects[movie_file_name]
o.write(:file => movie_file_name)

puts "To see the movie, visit this URL:"
puts o.url_for(:read)

puts "********** DONE! **********"
