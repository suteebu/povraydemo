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

# Creating JuliaIsleQueue
sqs = AWS::SQS.new
queue = sqs.queues.create("JuliaIsleQueue")
puts "Created JuliaIsleQueue"
pp sqs.queues.collect(&:url)

# Construct POV frames for movie
# TO DO: Consider making these arguments of the original povraydemo-server.rb call

# starting position
loc_x_0 = -1.5
loc_y_0 =  2.5
loc_z_0 = -1.0

# ending position
loc_x_f =  1.5
loc_y_f =  0.25
loc_z_f = -1.0

# iterate through frames
duration   = 5 # seconds
fps        = 30
num_frames = (duration * fps).ceil #returns Integer ceiling

puts "\n"
puts "********** QUEUEING POV-RAY FRAMES (#{num_frames} total) **********"

loc_x = Array.new
loc_y = Array.new
loc_z = Array.new

for f in 0..num_frames
  loc_x[f] = loc_x_0 + (loc_x_f - loc_x_0) * f / num_frames
  loc_y[f] = loc_y_0 + (loc_y_f - loc_y_0) * f / num_frames
  loc_z[f] = loc_z_0 + (loc_z_f - loc_z_0) * f / num_frames

  location_text = "location <#{loc_x[f]},#{loc_y[f]},#{loc_z[f]}>"

  num_zeros = "#{num_frames}".length - "#{f}".length
  frame_num_text = "0"*num_zeros + "#{f}"

  header = "/* frame#{frame_num_text} */"
  povpart1 = File.read("juliaisle.pov.fragment1")
  povcamera = "camera {\n" +
    "\tup <0,1,0>\n" +
    "\tright <1,0,0>\n" +
    "\t#{location_text}\n" +
    "\tlook_at <-0.1,0.15,0>\n" +
    "\tangle 20\n" +
    "}"
  povpart2 = File.read("juliaisle.pov.fragment2")

  povfull = header + "\n" + povpart1 + "\n" + povcamera + "\n" + povpart2
  msg = queue.send_message(povfull)
  puts "Queued frame#{frame_num_text}: #{location_text}"
end

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

# DEPLOY SPOT INSTANCES AND GIVE THEM BUCKET NAME


=begin
puts "\n"
puts "********** DEPLOYING SPOT INSTANCES **********"

################################

require 'net/http'
gem 'net-ssh', '~> 2.1.4'
require 'net/ssh'

instance = key_pair = group = nil

begin
  ec2 = AWS::EC2.new

  # optionally switch to a non-default region
  if region = ARGV.first
    region = ec2.regions[region]
    unless region.exists?
      puts "Requested region '#{region.name}' does not exist.  Valid regions:"
      puts "  " + ec2.regions.map(&:name).join("\n  ")
      exit 1
    end

    # a region acts like the main EC2 interface
    ec2 = region
  end

  # find the latest 32-bit EBS Amazon Linux AMI
  image = AWS.memoize do
    amazon_linux = ec2.images.with_owner("amazon").
      filter("root-device-type", "ebs").
      filter("architecture", "i386").
      filter("name", "amzn-ami*")

    # this only makes one request due to memoization
    amazon_linux.to_a.sort_by(&:name).last
  end
  puts "Using AMI: #{image.id}"

  # generate a key pair
  key_pair = ec2.key_pairs.create("ruby-sample-#{Time.now.to_i}")
  puts "Generated keypair #{key_pair.name}, fingerprint: #{key_pair.fingerprint}"

  # open SSH access
  group = ec2.security_groups.create("ruby-sample-#{Time.now.to_i}")
  group.authorize_ingress(:tcp, 22, "0.0.0.0/0")
  puts "Using security group: #{group.name}"

  # launch the instance
  instance = image.run_instance(:key_pair => key_pair,
                                :security_groups => group)
  sleep 1 until instance.status != :pending
  puts "Launched instance #{instance.id}, status: #{instance.status}"

  exit 1 unless instance.status == :running

  begin
    Net::SSH.start(instance.ip_address, "ec2-user",
                   :key_data => [key_pair.private_key]) do |ssh|
      puts "Running 'uname -a' on the instance yields:"
      puts ssh.exec!("uname -a")
    end
  rescue SystemCallError, Timeout::Error => e
    # port 22 might not be available immediately after the instance finishes launching
    sleep 1
    retry
  end

ensure
  # clean up
  [instance,
   group,
   key_pair].compact.each(&:delete)
end

###############################
=end



# CHECK QUEUE LENGTH PERIODICALLY AND SEE WHAT SPOT INSTANCES HAVE CHECKED IN FOR DUTY

#sleep(5)
#puts "Approx Number of messages: #{queue.approximate_number_of_messages}"

}

puts "********** DONE! **********"

puts "********** RUN povraydemo-client.rb **********
