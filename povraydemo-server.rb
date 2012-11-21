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

# CREATE JULIA ISLE QUEUE
sqs = AWS::SQS.new
queue = sqs.queues.create("JuliaIsleQueue")
puts "Created JuliaIsleQueue"
pp sqs.queues.collect(&:url)

# QUEUE POV-RAY FRAMES FOR MOVIES
# TO DO: Consider making these arguments of the original povraydemo-server.rb call

# starting position
loc_x_0 = -1.5
loc_y_0 =  2.5
loc_z_0 = -1.0

# ending position
#loc_x_f =  1.5
#loc_y_f =  0.25
#loc_z_f = -1.0
loc_x_f =  0.0018328
loc_y_f =  0.2501
loc_z_f =  0.002515

# iterate through frames
duration   = 10 # seconds
fps        = 30
num_frames = (duration * fps).ceil #returns Integer ceiling

puts "\n"
puts "********** QUEUEING POV-RAY FRAMES (#{num_frames} total) **********"

loc_x = Array.new
loc_y = Array.new
loc_z = Array.new

for f in 1..num_frames
  #loc_x[f] = loc_x_0 + (loc_x_f - loc_x_0) * f / num_frames
  #loc_y[f] = loc_y_0 + (loc_y_f - loc_y_0) * f / num_frames
  #loc_z[f] = loc_z_0 + (loc_z_f - loc_z_0) * f / num_frames

  final_fraction = Float(0.001)
  scale_factor = final_fraction**(1.0/(num_frames-1))
  loc_x[f] = loc_x_0 + (loc_x_f - loc_x_0) * (1-scale_factor**(f-1))
  loc_y[f] = loc_y_0 + (loc_y_f - loc_y_0) * (1-scale_factor**(f-1))
  loc_z[f] = loc_z_0 + (loc_z_f - loc_z_0) * (1-scale_factor**(f-1))

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

# CHECK QUEUE LENGTH PERIODICALLY AND SEE WHAT SPOT INSTANCES HAVE CHECKED IN FOR DUTY

count_empty = 0
while count_empty < 3 do
  msgs_left = queue.approximate_number_of_messages
  if msgs_left == 0 then
    count_empty += 1
  end
  puts "Approx number of msgs left: #{queue.approximate_number_of_messages}"
  sleep(5)
end

puts "(press any key to download frames, render movie, and upload movie)"
$stdin.getc

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
`ffmpeg -qscale 5 -r 24 -b 64k -i frame%d.png #{movie_file_name}`

puts "Uploading #{movie_file_name} to S3..."
# Upload Movie file
o = b.objects[movie_file_name]
o.write(:file => movie_file_name)

puts "To see the movie, visit this URL:"
puts o.url_for(:read)

puts "********** DONE! **********"
