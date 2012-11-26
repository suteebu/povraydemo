/* --------------------------
Entry: 0008
WWW: http://3dimensions.dhs.org
Title: Julia Set Isle
Author: Sascha Ledinsky
Computing the CPM julia set in POV's SDL is very slow, but as the rules say "The POVRay scene file entered must be totally self contained and not rely on any external files" (e.g. a height field created with an external fractal program like Ultrafractal) it's the only possibility...
---------------------------*/

#include "colors.inc"

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
	location <0, 2.5*3, 0>
	look_at <0,0,0>
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
	
	
object{ sphere{ <-3.2825110925828285,5.789746057780307,-1.453022894805549> 0.01 texture{ pigment{ Red } } } }
object{ sphere{ <-1.5,2.5,-1.0> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-3.2825110925828285,5.789746057780307,-1.453022894805549>, <-1.5,2.5,-1.0>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.3838393079284891,0.8212481078479678,-0.6396379123755445> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-1.5,2.5,-1.0>, <-0.3838393079284891,0.8212481078479678,-0.6396379123755445>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.2885137411678682,0.11112897781935302,-0.3562196151875815> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.3838393079284891,0.8212481078479678,-0.6396379123755445>, <0.2885137411678682,0.11112897781935302,-0.3562196151875815>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.668841553633812,-0.044401476499243,-0.13589676968874045> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.2885137411678682,0.11112897781935302,-0.3562196151875815>, <0.668841553633812,-0.044401476499243,-0.13589676968874045>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.8600908335399609,0.09296582093455569,0.03324468139661905> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.668841553633812,-0.044401476499243,-0.13589676968874045>, <0.8600908335399609,0.09296582093455569,0.03324468139661905>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.9316067064844813,0.36221311070079,0.16127171152104391> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.8600908335399609,0.09296582093455569,0.03324468139661905>, <0.9316067064844813,0.36221311070079,0.16127171152104391>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.9296984806247395,0.6680299408086307,0.25657065229520254> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.9316067064844813,0.36221311070079,0.16127171152104391>, <0.9296984806247395,0.6680299408086307,0.25657065229520254>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.8849518722629857,0.957312886008546,0.32604706781723836> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.9296984806247395,0.6680299408086307,0.25657065229520254>, <0.8849518722629857,0.957312886008546,0.32604706781723836>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.817276819137832,1.2034995310786707,0.37533152708449535> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.8849518722629857,0.957312886008546,0.32604706781723836>, <0.817276819137832,1.2034995310786707,0.37533152708449535>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.739381770802488,1.3962305079480077,0.4089756163338825> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.817276819137832,1.2034995310786707,0.37533152708449535>, <0.739381770802488,1.3962305079480077,0.4089756163338825>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.6591565391215652,1.5346148465214922,0.4306301105380661> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.739381770802488,1.3962305079480077,0.4089756163338825>, <0.6591565391215652,1.5346148465214922,0.4306301105380661>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.5812996978717235,1.6229156906824687,0.4432019387322771> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.6591565391215652,1.5346148465214922,0.4306301105380661>, <0.5812996978717235,1.6229156906824687,0.4432019387322771>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.5084243837431583,1.6678482537739978,0.44898940839654267> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.5812996978717235,1.6229156906824687,0.4432019387322771>, <0.5084243837431583,1.6678482537739978,0.44898940839654267>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.44180500933032824,1.6769405563028568,0.4497967603658021> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.5084243837431583,1.6678482537739978,0.44898940839654267>, <0.44180500933032824,1.6769405563028568,0.4497967603658021>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.3818776178720349,1.6575854820560156,0.44702995121926187> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.44180500933032824,1.6769405563028568,0.4497967603658021>, <0.3818776178720349,1.6575854820560156,0.44702995121926187>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.3285719140225197,1.616534753104392,0.44177590004600886> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.3818776178720349,1.6575854820560156,0.44702995121926187>, <0.3285719140225197,1.616534753104392,0.44177590004600886>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.28152885588201726,1.559668797732905,0.43486748529608144> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.3285719140225197,1.616534753104392,0.44177590004600886>, <0.28152885588201726,1.559668797732905,0.43486748529608144>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.24024091108502904,1.4919331600160568,0.42693646133440344> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.28152885588201726,1.559668797732905,0.43486748529608144>, <0.24024091108502904,1.4919331600160568,0.42693646133440344>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.20414043762767564,1.417370404191559,0.418456263784032> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.24024091108502904,1.4919331600160568,0.42693646133440344>, <0.20414043762767564,1.417370404191559,0.418456263784032>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.17265359064868693,1.339202174882149,0.40977643778191375> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.20414043762767564,1.417370404191559,0.418456263784032>, <0.17265359064868693,1.339202174882149,0.40977643778191375>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.14523159057454685,1.2599331795165274,0.40115018383065587> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.17265359064868693,1.339202174882149,0.40977643778191375>, <0.14523159057454685,1.2599331795165274,0.40115018383065587>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.12136735524641565,1.1814601178860862,0.3927562889536369> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.14523159057454685,1.2599331795165274,0.40115018383065587>, <0.12136735524641565,1.1814601178860862,0.3927562889536369>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.10060286809341928,1.1051758916913037,0.38471650499427656> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.12136735524641565,1.1814601178860862,0.3927562889536369>, <0.10060286809341928,1.1051758916913037,0.38471650499427656>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.08253085617031294,1.032064084180955,0.37710925463825573> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.10060286809341928,1.1051758916913037,0.38471650499427656>, <0.08253085617031294,1.032064084180955,0.37710925463825573>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.06679312844781467,0.9627815942756709,0.3699803894915126> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.08253085617031294,1.032064084180955,0.37710925463825573>, <0.06679312844781467,0.9627815942756709,0.3699803894915126>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.05307709718273031,0.8977290441288183,0.3633515919876036> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.06679312844781467,0.9627815942756709,0.3699803894915126>, <0.05307709718273031,0.8977290441288183,0.3633515919876036>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.04111144935866571,0.837109561441711,0.35722690181011607> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.05307709718273031,0.8977290441288183,0.3633515919876036>, <0.04111144935866571,0.837109561441711,0.35722690181011607>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.030661565130403086,0.78097704137558,0.35159775532864856> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.04111144935866571,0.837109561441711,0.35722690181011607>, <0.030661565130403086,0.78097704137558,0.35159775532864856>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.02152503656661032,0.7292751993389535,0.3464468506519153> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.030661565130403086,0.78097704137558,0.35159775532864856>, <0.02152503656661032,0.7292751993389535,0.3464468506519153>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.013527481884532226,0.6818687547815884,0.3417510888314176> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.02152503656661032,0.7292751993389535,0.3464468506519153>, <0.013527481884532226,0.6818687547815884,0.3417510888314176>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.00651874974326018,0.6385680148568693,0.3374837912684453> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.013527481884532226,0.6818687547815884,0.3417510888314176>, <0.00651874974326018,0.6385680148568693,0.3374837912684453>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.00036954582024223415,0.5991480046903397,0.333616352518633> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.00651874974326018,0.6385680148568693,0.3374837912684453>, <0.00036954582024223415,0.5991480046903397,0.333616352518633>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.005031523220643236,0.5633631485383472,0.3301194547562122> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.00036954582024223415,0.5991480046903397,0.333616352518633>, <-0.005031523220643236,0.5633631485383472,0.3301194547562122>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.009780513989814665,0.5309583615454123,0.3269639437154572> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.005031523220643236,0.5633631485383472,0.3301194547562122>, <-0.009780513989814665,0.5309583615454123,0.3269639437154572>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.013960354762901698,0.5016772753392924,0.3241214447630092> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.009780513989814665,0.5309583615454123,0.3269639437154572>, <-0.013960354762901698,0.5016772753392924,0.3241214447630092>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.017642737694872672,0.4752681974947419,0.3215647808696996> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.013960354762901698,0.5016772753392924,0.3241214447630092>, <-0.017642737694872672,0.4752681974947419,0.3215647808696996>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.020889734462140555,0.4514882969677453,0.3192682408182998> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.017642737694872672,0.4752681974947419,0.3215647808696996>, <-0.020889734462140555,0.4514882969677453,0.3192682408182998>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.023755172665856986,0.43010641509942704,0.3172077353280154> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.020889734462140555,0.4514882969677453,0.3192682408182998>, <-0.023755172665856986,0.43010641509942704,0.3172077353280154>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.026285806957614843,0.4109048238147842,0.31536087034666976> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.023755172665856986,0.43010641509942704,0.3172077353280154>, <-0.026285806957614843,0.4109048238147842,0.31536087034666976>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.02852231505024911,0.393680187772832,0.3137069601107032> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.026285806957614843,0.4109048238147842,0.31536087034666976>, <-0.02852231505024911,0.393680187772832,0.3137069601107032>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.030500144955432736,0.37824393383777166,0.3122269973405752> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.02852231505024911,0.393680187772832,0.3137069601107032>, <-0.030500144955432736,0.37824393383777166,0.3122269973405752>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.03225023617489954,0.3644221877021148,0.3109035938345132> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.030500144955432736,0.37824393383777166,0.3122269973405752>, <-0.03225023617489954,0.3644221877021148,0.3109035938345132>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.0337996342799382,0.35205540226655324,0.3097209015136979> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.03225023617489954,0.3644221877021148,0.3109035938345132>, <-0.0337996342799382,0.35205540226655324,0.3097209015136979>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.03517201539090097,0.34099777408397774,0.30866452147040113> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.0337996342799382,0.35205540226655324,0.3097209015136979>, <-0.03517201539090097,0.34099777408397774,0.30866452147040113>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.03638813451958865,0.3311165215934884,0.3077214066283256> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.03517201539090097,0.34099777408397774,0.30866452147040113>, <-0.03638813451958865,0.3311165215934884,0.3077214066283256>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.03746620954333417,0.322291080964095,0.3068797621227906> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.03638813451958865,0.3311165215934884,0.3077214066283256>, <-0.03746620954333417,0.322291080964095,0.3068797621227906>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.038422250709047256,0.3144122612577102,0.30612894635312304> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.03746620954333417,0.322291080964095,0.3068797621227906>, <-0.038422250709047256,0.3144122612577102,0.30612894635312304>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.03927034398198767,0.307381389573379,0.3054593747758232> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.038422250709047256,0.3144122612577102,0.30612894635312304>, <-0.03927034398198767,0.307381389573379,0.3054593747758232>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.040022895220562245,0.3011094682429829,0.30486242783550865> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.03927034398198767,0.307381389573379,0.3054593747758232>, <-0.040022895220562245,0.3011094682429829,0.30486242783550865>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.04069084103975452,0.2955163595159373,0.30433036392447665> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.040022895220562245,0.3011094682429829,0.30486242783550865>, <-0.04069084103975452,0.2955163595159373,0.30433036392447665>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.04128383128973828,0.2905300080922337,0.3038562378840295> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.04069084103975452,0.2955163595159373,0.30433036392447665>, <-0.04128383128973828,0.2905300080922337,0.3038562378840295>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.041810387294307555,0.28608570801209093,0.3034338252824088> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.04128383128973828,0.2905300080922337,0.3038562378840295>, <-0.041810387294307555,0.28608570801209093,0.3034338252824088>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.04227803934115152,0.2821254175232194,0.3030575525024443> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.041810387294307555,0.28608570801209093,0.3034338252824088>, <-0.04227803934115152,0.2821254175232194,0.3030575525024443>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.0426934463714449,0.2785971234123027,0.3027224325289668> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.04227803934115152,0.2821254175232194,0.3030575525024443>, <-0.0426934463714449,0.2785971234123027,0.3027224325289668>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.043062500361671044,0.27545425473748075,0.30242400622765103> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.0426934463714449,0.2785971234123027,0.3027224325289668>, <-0.043062500361671044,0.27545425473748075,0.30242400622765103>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.043390417510839635,0.27265514480004616,0.3021582888423727> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.043062500361671044,0.27545425473748075,0.30242400622765103>, <-0.043390417510839635,0.27265514480004616,0.3021582888423727>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.04368181802860844,0.27016253944056373,0.3019217213988861> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.043390417510839635,0.27265514480004616,0.3021582888423727>, <-0.04368181802860844,0.27016253944056373,0.3019217213988861>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.043940796053682424,0.26794314925421203,0.3017111266821124> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.04368181802860844,0.27016253944056373,0.3019217213988861>, <-0.043940796053682424,0.26794314925421203,0.3017111266821124>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.04417098100846038,0.26596724302725894,0.3015236694475102> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.043940796053682424,0.26794314925421203,0.3017111266821124>, <-0.04417098100846038,0.26596724302725894,0.3015236694475102>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.044375591507982,0.2642082795502999,0.30135682052999> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.04417098100846038,0.26596724302725894,0.3015236694475102>, <-0.044375591507982,0.2642082795502999,0.30135682052999>, 0.01 open texture{ pigment{ Red } } } }