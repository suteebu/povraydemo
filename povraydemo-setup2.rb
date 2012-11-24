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
queue = sqs.queues.create("JuliaIsleQueue", :visibility_timeout=>300)
puts "Created JuliaIsleQueue"
pp sqs.queues.collect(&:url)

# QUEUE POV-RAY FRAMES FOR MOVIES
# TO DO: Consider making these arguments of the original povraydemo-server.rb call

###########

# spline control points
cx = [-1.5,  2.0, 0.5,  0.0018328]
cy = [ 2.5, -3.0,  2.5,  0.2501]
cz = [-1.0,  0.25,  0.0,  0.002515]

# iterate through frames
duration   = 10 # seconds
fps        = 30
num_frames = (duration * fps).ceil #returns Integer ceiling

# path points
px = Array.new
py = Array.new
pz = Array.new

povpart2 = ""

for f in 0..num_frames
  t = 0.0

  spacing = "even"
  if spacing == "even" then
    t = Float(f)/num_frames
  elsif spacing == "exponential" then
    fration = Float(f)/num_frames
    final_fraction = Float(0.001)
    scale_factor = final_fraction**(1.0/(num_frames-1))
    t = 1-scale_factor**(f-1)
  end

  coeff = [(1-t)**3, 3*t*(1-t)**2, 3*(t**2)*(1-t), t**3]
  px[f] = coeff[0]*cx[0] + coeff[1]*cx[1] + coeff[2]*cx[2] + coeff[3]*cx[3]
  py[f] = coeff[0]*cy[0] + coeff[1]*cy[1] + coeff[2]*cy[2] + coeff[3]*cy[3]
  pz[f] = coeff[0]*cz[0] + coeff[1]*cz[1] + coeff[2]*cz[2] + coeff[3]*cz[3]
end

puts "\n"
puts "********** QUEUEING POV-RAY FRAMES (#{num_frames} total) **********"

loc_x = Array.new
loc_y = Array.new
loc_z = Array.new

for f in 0..num_frames-1
  location_text = "<#{px[f]},#{py[f]},#{pz[f]}>"
  lookat_text =   "<#{px[f+1]},#{py[f+1]},#{pz[f+1]}>"

  num_zeros = "#{num_frames}".length - "#{f}".length
  frame_num_text = "0"*num_zeros + "#{f}"

  header = "/* frame#{frame_num_text} */"
  povpart1 = File.read("juliaisle.pov.fragment1")
  povcamera = "camera {\n" +
    "\tup <0,1,0>\n" +
    "\tright <1,0,0>\n" +
    "\tlocation #{location_text}\n" +
    "\tlook_at #{lookat_text}\n" +
    "\tangle 20\n" +
    "}"
  povpart2 = File.read("juliaisle.pov.fragment2")

  povfull = header + "\n" + povpart1 + "\n" + povcamera + "\n" + povpart2
  msg = queue.send_message(povfull)
  puts "Queued frame#{frame_num_text}: #{location_text}"
end

puts "********** FINISHED SPOOLING POV-RAY FILES TO SQS QUEUE **********"
