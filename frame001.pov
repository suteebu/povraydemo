/* frame001 */
/* --------------------------
Entry: 0008
WWW: http://3dimensions.dhs.org
Title: Julia Set Isle
Author: Sascha Ledinsky
Computing the CPM julia set in POV's SDL is very slow, but as the rules say "The POVRay scene file entered must be totally self contained and not rely on any external files" (e.g. a height field created with an external fractal program like Ultrafractal) it's the only possibility...
---------------------------*/

/*
 * Continous Potential Method (CPM) Julia set
 * released into public domain
 */
/* -------------------------------------------------------------------------------------------------- */
/* corners */
#local iMin = -1.2;
#local iMax = +1.2;
#local rMin = -2.4;
#local rMax = +2.4;
/* julia set for */
#local rJulia = -1.09;
#local iJulia = 0.24;
/* resolution */
#local xSteps = 1000;
#local ySteps = 500;
/* maximum iterations and bailout */
#local itMax = 50;
#local bMax = 1000;
/* -------------------------------------------------------------------------------------------------- */
#local dr = (rMax - rMin) / xSteps;
#local di = (iMax - iMin) / ySteps;
#local log2 = log(2);
#local height = array[xSteps][ySteps];
/* create height field */
#debug concat("computing ",str(xSteps,0,0),"x",str(ySteps,0,0)," height field...\n\n")
#declare f_bozo = function { pattern { bozo } }
#local i = iMin;
#local Y = 0;
#while (Y < ySteps)
	#local r = rMin;
	#local X = 0;
	#while (X < xSteps)
		#local it = 0;
		#local zr = r;
		#local zi = i;
		#local b = zr*zr + zi*zi;
		#while (b < bMax & it < itMax)
			/* julia set */
			#local zrOld = zr;
			#local zr = zr*zr - zi*zi + rJulia;
			#local zi = 2*zrOld*zi + iJulia;
			#local b = zr*zr + zi*zi;
			#local it = it + 1;
		#end
		#if (it = itMax)
			#local height[X][Y] = 0;
		#else
			/* cpm "potential" */
			#local potential = -pow(log(sqrt(b))/log2/pow(2,it),1/4);
			#local bump = 0;
			/* add some bumps to sand */
			#if (potential < -0.15)
				#local m = min(0.15 + potential,0.15);
				#local bump = m * f_bozo(X*0.1,0,Y*0.1) * 0.075;
			#end
			#local height[X][Y] = potential - bump;
			
		#end
		#local r = r + dr;
		#local X = X + 1;
	#end
	#local i = i + di;
	#local Y = Y + 1;
	#debug concat("\r",str(Y/ySteps*100,0,0),"% completed")
#end
/* some textures */
#declare fractal_texture = texture {
	pigment {
		julia <rJulia,iJulia>,itMax * 4
		rotate <90,0,0>
		/* map mandelbrot pattern to specified coordinates */
		translate <-rMin,0,-iMin>
		scale <1/(rMax - rMin),1,1/(iMax - iMin)>
		color_map {
			[0.0 color rgb <0.15,0.3,0.05>]
			[0.2 color rgb <0.1,0.2,0.0>]
			[0.3 color rgb <1,0,0>]
			[0.5 color rgb <1,1,0>]
			[0.7 color rgb <1,1,1>]
			[0.9 color rgb <0,0,1>]
			[1.0 color rgb <0,0,0>]
		}
	}
	finish { diffuse 1 ambient 0}
}
#declare rock_texture = texture {
	pigment {
		granite
		color_map {
			[0.0 color rgb <0.25,0.2,0.15>]
			[0.1 color rgb <0.25,0.2,0.15>]
			[0.9 color rgb <0.25,0.2,0.15>*0.5]
			[1.0 color rgb <0.25,0.2,0.15>*0.5]
		}
		turbulence 10
		omega 0.6
		octaves 10
		scale <5,30,5>
		rotate <5,5,5>
	}
	finish { diffuse 1 ambient 0 specular 0.5 roughness 0.02 }
}
#declare sand_texture = texture {
	pigment { color rgb <0.9,0.7,0.4> }
	finish { diffuse 1 brilliance 0.7 ambient 0 specular 0.7 roughness 0.05 crand 0.25 }
}
#declare land_texture = texture {
	slope { <0,-1,0>,0,0.5 }
	texture_map {
		[0.0 sand_texture]
		[0.5 sand_texture]
		[0.8 rock_texture]
		[1.0 rock_texture]
	}
}
#declare black_texture = texture {
	pigment { color rgb <0,0.1,0.3> }
	finish { ambient 1 diffuse 0 }
}
/*
 * set up the mesh2
 */
mesh2 {
	#debug concat("\rsetting up grid vertices...\n\n")
	vertex_vectors {
		(xSteps - 2)*(ySteps - 2)
		#local Y = 1;
		#while (Y < ySteps - 1)
			#local X = 1;
			#while (X < xSteps - 1)
				<X/xSteps,height[X][Y],Y/ySteps>,
				#local X = X + 1;
			#end
			#local Y = Y + 1;
			#debug concat("\r",str((Y+1)/ySteps*100,0,0),"% completed")
		#end
	}
	#local xs = 2 / xSteps;
	#local ys = 2 / ySteps;
	#debug concat("\rsetting up surface normals...\n\n")
	normal_vectors {
		(xSteps - 2)*(ySteps - 2)
		#local Y = 1;
		#while (Y < ySteps - 1)
			#local X = 1;
			#while (X < xSteps - 1)
				#if (height[X][Y] >= 1)
					<0,1,0>
				#else
					/* compute surface normal */
					#local dx = <xs,height[X + 1][Y] - height[X - 1][Y],0>;
					#local dz = <0,height[X][Y + 1] - height[X][Y - 1],ys>;
					vnormalize(vcross(dx,dz))
				#end
				#local X = X + 1;
			#end
			#local Y = Y + 1;
			#debug concat("\r",str((Y+1)/ySteps*100,0,0),"% completed")
		#end
	}
	#debug concat("\rbuilding triangle mesh...\n\n")
	face_indices {
		(xSteps - 3)*(ySteps -3)*2
		#local f = xSteps - 2;
		#local Y = 0;
		#while (Y < ySteps - 3)
			#local X = 0;
			#while (X < xSteps - 3)
				<Y*f + X,Y*f + X + 1,(Y + 1)*f + X>
				<(Y + 1)*f + X + 1,(Y + 1)*f + X,Y*f + X + 1>
				#local X = X + 1;
			#end
			#local Y = Y + 1;
			#debug concat("\r",str((Y+3)/ySteps*100,0,0),"% completed")
		#end
	}
	texture {
		gradient y
		texture_map {
			[0.0 black_texture]
			[0.3 black_texture]
			[0.5 land_texture]
			[0.8 land_texture]
			[0.9 fractal_texture]
			[1.0 fractal_texture]
		}
		scale <1,1.2,1>
		translate y*0.1
	}		
	scale <2,0.4,1>
	translate <-1,0.25,-0.5>
}
#debug concat("\rrendering...  \n\n")
/*
 * camera, lights, background, sea,...
 */
camera {
	up <0,1,0>
	right <1,0,0>
	location <-1.48,2.485,-1.0>
	look_at <-0.1,0.15,0>
	angle 20
}
light_source {
	<-10,12,5>
	color rgb <1.5,1.5,1>*1.2
	area_light <0.3,0,0>,<0,0.3,0>,5,5 circular orient jitter
}
light_source {
	<0,5,-10>
	color rgb <0.2,0.2,0.3>*1.2
	shadowless
}
light_source {
	<5,10,-5>
	color rgb <0.2,0.2,0.3>*1.2
	shadowless
}
sky_sphere {
	pigment {
		gradient y
		color_map {
			[0.0 color rgb <0.8,0.8,0.8>]
			[0.4 color rgb <0,0,1>]
			[1.0 color rgb <0,0,0.3>]
		}
	}
}
plane {
	y,-0.25
	texture { black_texture }
}
plane {
	y,0
	pigment {
		color rgbf <0.5,1,0.8,0.99>
	}
	finish {
		ambient 0
		diffuse 2
		brilliance 1.5
		specular 0.8 roughness 0.03
		reflection {
			0,1
			fresnel on        
		}
		conserve_energy
	}
	normal {
		average
		normal_map {
			[0.5 bumps 0.9 scale <0.005,0.01,0.01> rotate <0,-60,0>]
			[0.5 bumps 0.4 scale 0.003]
		}
	}
	interior {
		ior 1.33
		fade_power 2
		fade_distance 0.1
	}
}
plane {
	y,-0.1
	pigment {
		granite
		color_map {
			[0.0 color rgbt <0.9,0.8,0.6,1>]
			[0.5 color rgbt <0.9,0.8,0.6,1>]
			[1.0 color rgbt <0.9,0.8,0.6,0.5>]
		}
		scale 2
	}
	finish {
		ambient 0.5 diffuse 0
	}
}
	
	