# This demo shows how to use Amazon EC2 Spot Instances and Amazon SQS to
# generate the movie images for a fly-by of a Julia Set Island.

require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'pp'

#this file has my AWS access key and private key
config_file = File.join(File.dirname(__FILE__),
                        "config.yml")

unless File.exist?(config_file)
  puts <<END
To run the samples, put your credentials in config.yml as follows:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY

END
  exit 1
end

config = YAML.load(File.read(config_file))

unless config.kind_of?(Hash)
  puts <<END
config.yml is formatted incorrectly.  Please use the following format:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY

END
  exit 1
end

AWS.config(config)

### READ FROM SQS QUEUE

# Accessing JuliaIsleQueue
sqs = AWS::SQS.new
q_url = "https://sqs.us-east-1.amazonaws.com/976995352265/JuliaIsleQueue"
queue = sqs.queues[q_url]

# get an instance of the S3 interface using the default configuration
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

# Creating a checking file token in the S3 bucket to indicate I'm working
checkin_file_name = "client_checkin_" + Time.new.to_i.to_s
puts "Writing checkin file in S3: #{checkin_file_name}"
o_checkin_file = b.objects[checkin_file_name]
o_checkin_file.write('Checking in for duty!')

# TAKE ONE QUEUE ITEM AND RENDER IT
queue.poll(:idle_timeout => 10) {|msg|
  # print header line of pov file
  header = msg.body.split("\n")[0]
  puts "Got message: #{header}"
  frame_name = header.scan(/\/\*\s*(\w*)\s*\*\//)[0][0]
  pov_file_name = frame_name + ".pov"
  pic_file_name = frame_name + ".png"
  log_file_name = frame_name + ".log"

  pic_height = 1000
  pic_width  = 1000

  File.open(pov_file_name, 'w') {|f| f.write(msg.body) }
  puts "Rendering #{pov_file_name}... (this step may take several minutes)"
  `povray +O#{pic_file_name} -h#{pic_height} -w#{pic_width} #{pov_file_name} 2> #{log_file_name}`

  puts "Uploading #{pic_file_name} to s3..."

  # upload a file
  o = b.objects[pic_file_name]
  o.write(:file => pic_file_name)

  puts "*** Uploaded #{pic_file_name} to: #{o.public_url}"
  # generate a presigned URL
  puts "*** Use this URL to download the file: #{o.url_for(:read)}"
  
#  puts "(press any key to delete the object)"
#  $stdin.getc

#  o.delete

#  puts "Done."
}

# rending movie
#fmpeg -qscale 5 -r 24 -b 64k -i frame%03d.png movie.mp4


puts "********** DONE! **********"

# remove my checkin_file from s3
o_checkin_file.delete
