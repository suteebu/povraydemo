# This demo shows how to use Amazon EC2 Spot Instances and Amazon SQS to
# generate the movie images for a fly-by of a Julia Set Island.

require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'pp'
require 'trollop'
require 'net/http'

# I CAN BE RUN WITH NO ARGUMENTS
# BUT THE FOLLOWING OPTIONS ARE AVAILABLE
@opts = Trollop::options do
  opt :width, "Width of POV image", :default=>1000
  opt :height, "Height of POV image", :default=>1000
  opt :cleanup_files, "Clean-up .pov, .png, and .log files after completion", :default=>true
  opt :self_terminate, "Self-terminate the EC2 Instance hosting this script", :default=>false
end
puts @opts.inspect

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

files = Array.new()
i = 0

# TAKE ONE QUEUE ITEM AND RENDER IT
queue.poll(:idle_timeout => 10) {|msg|
  # print header line of pov file
  header = msg.body.split("\n")[0]
  puts "Got message: #{header}"
  frame_name = header.scan(/\/\*\s*(\w*)\s*\*\//)[0][0]
  pov_file_name = frame_name + ".pov"
  pic_file_name = frame_name + ".png"
  log_file_name = frame_name + ".log"

  files[i] = pov_file_name
  i += 1
  files[i] = pic_file_name
  i += 1
  files[i] = log_file_name
  i += 1

  pic_height = @opts[:height]
  pic_width  = @opts[:width]

  File.open(pov_file_name, 'w') {|f| f.write(msg.body) }
  puts "Rendering #{pov_file_name}... (this step may take several minutes)"

=begin
  `povray +O#{pic_file_name} -h#{pic_height} -w#{pic_width} #{pov_file_name} 2> #{log_file_name}`

  puts "Uploading #{pic_file_name} to s3..."

  # upload a file
  o = b.objects[pic_file_name]
  o.write(:file => pic_file_name)

  puts "*** Uploaded #{pic_file_name} to: #{o.public_url}"
  # generate a presigned URL
  puts "*** Use this URL to download the file: #{o.url_for(:read)}"
=end
}

puts "********** DONE! (or didn't see a new SQS item for 10 seconds) **********"

# remove my checkin_file from s3
puts "Removing my check-in file from S3..."
o_checkin_file.delete

# CLEAN-UP FILES
if @opts[:cleanup_files] then
  puts "Deleting working files (.pov, .png, .log)...."
  files.each do |filename|
    begin
      File.delete(filename)
    rescue Errno::ENOENT => e
      puts "ERROR: Can't delete #{filename}: " + e
    end
  end
end

# SELF-DESTRUCT
# If this program is runny from an EC2 instance, I can access the ec2
# meta data server, 169.254.169.254

if @opts[:self_terminate] then
  begin
    #this should probably be in a separate terminate instance ruby script
    http = Net::HTTP.new('169.254.169.254')
    http.start
    response = http.request(Net::HTTP::Get.new('/latest/meta-data/instance-id'))
    http.finish
    
    instance_id = response.body

    #terminate instance here  
    #alternatively: `shutdown -h now`
    ec2 = AWS::EC2.new()
    instance = ec2.instances[instance_id]
    instance.terminate()

  rescue Errno::EHOSTUNREACH => err
    puts "SELF_TERMINATE FAILED: Could not reach EC2 meta server at (169.254.169.254)."
    puts "This probably isn't an EC2 Instance and I can't terminate it."
    puts "Error: " + err

  rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
    Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
    puts "SELF-TERMINATE FAILED: Error making http request to EC2 meta server."
    puts "Error: " + e
  end
end
