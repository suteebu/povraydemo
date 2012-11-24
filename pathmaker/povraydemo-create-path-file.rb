# This demo shows how to use Amazon EC2 Spot Instances and Amazon SQS to
# generate the movie images for a fly-by of a Julia Set Island.

require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'pp'
require 'trollop'

@opts = Trollop::options do
  opt :input_file, "Name of the input .pov file", :type=>String, :default=>"juliaisle.pov"
  opt :output_file, "Name of the output .pov file", :type=>String, :default=>"juliaisle-withpath.pov"
end
puts @opts.inspect

# spline control points
#cx = [-1.5, 1.5,  1.5,  0.0018328]
cx = [-1.5,  2.0, 0.5,  0.0018328]
#cy = [ 2.5,  0.25, 0.25, 0.2501]
cy = [ 2.5, -3.0,  2.5,  0.2501]
#cz = [-1.0, -1.0,  1.0,  0.002515]
cz = [-1.0,  0.25,  0.0,  0.002515]

#loc_x_f =  0.0018328
#loc_y_f =  0.2501
#loc_z_f =  0.002515


# iterate through frames
duration   = 2 # seconds
fps        = 30
num_frames = (duration * fps).ceil #returns Integer ceiling

# path points
px = Array.new
py = Array.new
pz = Array.new

povpart2 = ""

for f in 0..num_frames

  t = 0.0

  spacing = "exponential"
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

  object_text =
    "object{ sphere{ " +
    "<#{px[f]},#{py[f]},#{pz[f]}> " + #center of sphere
    "0.01 " + #radius of sphere
    "texture{ pigment{ Red } } " +
    "} }"

  if f > 0 then
    object_text +=
      "object{ cylinder{ " +
      "<#{px[f-1]},#{py[f-1]},#{pz[f-1]}>, " + #center of sphere
      "<#{px[f]},#{py[f]},#{pz[f]}>, " + #center of sphere
      "0.01 " + #radius of sphere
      "open " +
      "texture{ pigment{ Red } } " +
      "} }"
  end    

  povpart2 += "\n" + object_text
end

povpart1 = File.read(@opts[:input_file])
povfull = povpart1 + povpart2
File.open(@opts[:output_file], 'w') {|f| f.write(povfull) }

