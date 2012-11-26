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
	location <-1.5*2, 2.5*3, -1.0*4>
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
	
	
object{ sphere{ <-3.047128846055148,5.094524936824803,-1.538572624300867> 0.01 texture{ pigment{ Red } } } }
object{ sphere{ <-1.5,2.5,-1.0> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-3.047128846055148,5.094524936824803,-1.538572624300867>, <-1.5,2.5,-1.0>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <-0.5149058293308026,1.0545238180869778,-0.6382446336126772> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-1.5,2.5,-1.0>, <-0.5149058293308026,1.0545238180869778,-0.6382446336126772>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.09290191510937909,0.32300966454288277,-0.3973070355242331> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <-0.5149058293308026,1.0545238180869778,-0.6382446336126772>, <0.09290191510937909,0.32300966454288277,-0.3973070355242331>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.4500093816474748,0.020709538982481002,-0.23853342598752444> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.09290191510937909,0.32300966454288277,-0.3973070355242331>, <0.4500093816474748,0.020709538982481002,-0.23853342598752444>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.6427446949587984,-0.03598351126510488,-0.13531942129370966> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.4500093816474748,0.020709538982481002,-0.23853342598752444>, <0.6427446949587984,-0.03598351126510488,-0.13531942129370966>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.7296422707588573,0.03683406040330013,-0.06941558087096128> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.6427446949587984,-0.03598351126510488,-0.13531942129370966>, <0.7296422707588573,0.03683406040330013,-0.06941558087096128>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.7501066098786757,0.16769201373733095,-0.028353439644458044> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.7296422707588573,0.03683406040330013,-0.06941558087096128>, <0.7501066098786757,0.16769201373733095,-0.028353439644458044>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.7304234906110284,0.31425941830420606,-0.003654673167569253> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.7501066098786757,0.16769201373733095,-0.028353439644458044>, <0.7304234906110284,0.31425941830420606,-0.003654673167569253>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.6879218834857859,0.45293302166105764,0.010412893456139091> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.7304234906110284,0.31425941830420606,-0.003654673167569253>, <0.6879218834857859,0.45293302166105764,0.010412893456139091>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.633848336345751,0.5718941255521139,0.017697830885460626> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.6879218834857859,0.45293302166105764,0.010412893456139091>, <0.633848336345751,0.5718941255521139,0.017697830885460626>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.5753463084946048,0.666524900467628,0.0207618981321591> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.633848336345751,0.5718941255521139,0.017697830885460626>, <0.5753463084946048,0.666524900467628,0.0207618981321591>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.5168143971697948,0.7364207834884383,0.02129194199990538> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.5753463084946048,0.666524900467628,0.0207618981321591>, <0.5168143971697948,0.7364207834884383,0.02129194199990538>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.460834446616876,0.7834753099160756,0.02038336501114665> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.5168143971697948,0.7364207834884383,0.02129194199990538>, <0.460834446616876,0.7834753099160756,0.02038336501114665>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.40880252202746226,0.8106795803890322,0.018734545499668066> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.460834446616876,0.7834753099160756,0.02038336501114665>, <0.40880252202746226,0.8106795803890322,0.018734545499668066>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.36135520119638015,0.8213930347973359,0.016779647928877733> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.40880252202746226,0.8106795803890322,0.018734545499668066>, <0.36135520119638015,0.8213930347973359,0.016779647928877733>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.31865534727430067,0.8189209839251751,0.014778912623713437> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.36135520119638015,0.8213930347973359,0.016779647928877733>, <0.31865534727430067,0.8189209839251751,0.014778912623713437>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.28058180224043927,0.806288384404204,0.012879684431810631> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.31865534727430067,0.8189209839251751,0.014778912623713437>, <0.28058180224043927,0.806288384404204,0.012879684431810631>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.24685370691974595,0.7861362572517031,0.011157373521031425> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.28058180224043927,0.806288384404204,0.012879684431810631>, <0.24685370691974595,0.7861362572517031,0.011157373521031425>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.21711060470883187,0.7606922496758138,0.009642708629591126> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.24685370691974595,0.7861362572517031,0.011157373521031425>, <0.21711060470883187,0.7606922496758138,0.009642708629591126>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.19096285878036304,0.7317838084939062,0.008339672228241463> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.21711060470883187,0.7606922496758138,0.009642708629591126>, <0.19096285878036304,0.7317838084939062,0.008339672228241463>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.16802232192299882,0.7008738259288001,0.007237138112123443> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.19096285878036304,0.7317838084939062,0.008339672228241463>, <0.16802232192299882,0.7008738259288001,0.007237138112123443>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.1479200258283495,0.6691062019795837,0.006316282839021182> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.16802232192299882,0.7008738259288001,0.007237138112123443>, <0.1479200258283495,0.6691062019795837,0.006316282839021182>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.1303154704034587,0.6373537616023831,0.0055551858170456055> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.1479200258283495,0.6691062019795837,0.006316282839021182>, <0.1303154704034587,0.6373537616023831,0.0055551858170456055>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.11490059191695944,0.6062642087878454,0.004931579711854626> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.1303154704034587,0.6373537616023831,0.0055551858170456055>, <0.11490059191695944,0.6062642087878454,0.004931579711854626>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.10140046115860944,0.5763018687788887,0.004424401043492605> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.11490059191695944,0.6062642087878454,0.004931579711854626>, <0.10140046115860944,0.5763018687788887,0.004424401043492605>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.08957206285084555,0.5477842571925652,0.004014577027755532> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.10140046115860944,0.5763018687788887,0.004424401043492605>, <0.08957206285084555,0.5477842571925652,0.004014577027755532>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.07920203346582126,0.5209132878595308,0.0036853386882382826> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.08957206285084555,0.5477842571925652,0.004014577027755532>, <0.07920203346582126,0.5209132878595308,0.0036853386882382826>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.07010391568833038,0.49580137031852756,0.003422251014534005> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.07920203346582126,0.5209132878595308,0.0036853386882382826>, <0.07010391568833038,0.49580137031852756,0.003422251014534005>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.06211527505756041,0.4724928742500276,0.0032130838778560086> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.07010391568833038,0.49580137031852756,0.003422251014534005>, <0.06211527505756041,0.4724928742500276,0.0032130838778560086>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.05509488397504299,0.4509815322882088,0.0030476024216979022> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.06211527505756041,0.4724928742500276,0.0032130838778560086>, <0.05509488397504299,0.4509815322882088,0.0030476024216979022>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.04892008695389275,0.4312243676314866,0.002917325723993825> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.05509488397504299,0.4509815322882088,0.0030476024216979022>, <0.04892008695389275,0.4312243676314866,0.002917325723993825>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.04348440267587068,0.41315270307004703,0.0028152828495526237> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.04892008695389275,0.4312243676314866,0.002917325723993825>, <0.04348440267587068,0.41315270307004703,0.0028152828495526237>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.03869538214491428,0.39668075535921254,0.002735782654756473> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.04348440267587068,0.41315270307004703,0.0028152828495526237>, <0.03869538214491428,0.39668075535921254,0.002735782654756473>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.03447272050055092,0.38171225687521937,0.00267420559244505> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.03869538214491428,0.39668075535921254,0.002735782654756473>, <0.03447272050055092,0.38171225687521937,0.00267420559244505>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.03074660781329999,0.36814548331513985,0.0026268207378156586> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.03447272050055092,0.38171225687521937,0.00267420559244505>, <0.03074660781329999,0.36814548331513985,0.0026268207378156586>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.02745629801364258,0.35587700642211856,0.0025906282588394453> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.03074660781329999,0.36814548331513985,0.0026268207378156586>, <0.02745629801364258,0.35587700642211856,0.0025906282588394453>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.024548872726722563,0.34480443665352456,0.002563225872889339> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.02745629801364258,0.35587700642211856,0.0025906282588394453>, <0.024548872726722563,0.34480443665352456,0.002563225872889339>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.021978176689501874,0.33482837328853354,0.002542696985924988> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.024548872726722563,0.34480443665352456,0.002563225872889339>, <0.021978176689501874,0.33482837328853354,0.002542696985924988>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.01970390263231494,0.32585373878506313,0.002527517883191385> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.021978176689501874,0.33482837328853354,0.002542696985924988>, <0.01970390263231494,0.32585373878506313,0.002527517883191385>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.0176908053820653,0.3177906398671514,0.002516481321583408> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.01970390263231494,0.32585373878506313,0.002527517883191385>, <0.0176908053820653,0.3177906398671514,0.002516481321583408>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.015908027094873132,0.3105548692398198,0.002508634027940456> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.0176908053820653,0.3177906398671514,0.002516481321583408>, <0.015908027094873132,0.3105548692398198,0.002508634027940456>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.014328517712945021,0.30406813828367163,0.0025032258483308886> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.015908027094873132,0.3105548692398198,0.002508634027940456>, <0.014328517712945021,0.30406813828367163,0.0025032258483308886>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.012928536826704124,0.29825811186324114,0.0024996685674924107> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.014328517712945021,0.30406813828367163,0.0025032258483308886>, <0.012928536826704124,0.29825811186324114,0.0024996685674924107>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.01168722503715646,0.2930583008201425,0.0024975026932382042> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.012928536826704124,0.29825811186324114,0.0024996685674924107>, <0.01168722503715646,0.2930583008201425,0.0024975026932382042>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.010586234624375572,0.2884078552079278,0.002496370760037057> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.01168722503715646,0.2930583008201425,0.0024975026932382042>, <0.010586234624375572,0.2884078552079278,0.002496370760037057>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.009609410830117229,0.2842512913285672,0.0024959959402373055> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.010586234624375572,0.2884078552079278,0.002496370760037057>, <0.009609410830117229,0.2842512913285672,0.0024959959402373055>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.008742516364492862,0.2805381776937193,0.0024961649571372297> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.009609410830117229,0.2842512913285672,0.0024959959402373055>, <0.008742516364492862,0.2805381776937193,0.0024961649571372297>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.00797299286452366,0.2772227987712902,0.002496714471188926> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.008742516364492862,0.2805381776937193,0.0024961649571372297>, <0.00797299286452366,0.2772227987712902,0.002496714471188926>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.007289753985758072,0.2742638104665558,0.0024975202607677104> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.00797299286452366,0.2772227987712902,0.002496714471188926>, <0.007289753985758072,0.2742638104665558,0.0024975202607677104>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.00668300561721975,0.2716238974606108,0.00249848864476637> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.007289753985758072,0.2742638104665558,0.0024975202607677104>, <0.00668300561721975,0.2716238974606108,0.00249848864476637>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.00614408939427636,0.26926943956840743,0.0024995496987500524> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.00668300561721975,0.2716238974606108,0.00249848864476637>, <0.00614408939427636,0.26926943956840743,0.0024995496987500524>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.005665346261519216,0.26717019200591036,0.0025006519025089235> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.00614408939427636,0.26926943956840743,0.0024995496987500524>, <0.005665346261519216,0.26717019200591036,0.0025006519025089235>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.005239997324490332,0.2652989827267571,0.0025017579273679228> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.005665346261519216,0.26717019200591036,0.0025006519025089235>, <0.005239997324490332,0.2652989827267571,0.0025017579273679228>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.00486203963914563,0.2636314286871211,0.0025028413290789178> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.005239997324490332,0.2652989827267571,0.0025017579273679228>, <0.00486203963914563,0.2636314286871211,0.0025028413290789178>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.004526154933429569,0.262145671930105,0.0025038839587446697> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.00486203963914563,0.2636314286871211,0.0025028413290789178>, <0.004526154933429569,0.262145671930105,0.0025038839587446697>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.004227629546636167,0.2608221356737642,0.002504873941911859> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.004526154933429569,0.262145671930105,0.0025038839587446697>, <0.004227629546636167,0.2608221356737642,0.002504873941911859>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.003962284118108841,0.25964330008071473,0.0025058041063374214> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.004227629546636167,0.2608221356737642,0.002504873941911859>, <0.003962284118108841,0.25964330008071473,0.0025058041063374214>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.0037264117646830176,0.25859349703558115,0.0025066707633324306> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.003962284118108841,0.25964330008071473,0.0025058041063374214>, <0.0037264117646830176,0.25859349703558115,0.0025066707633324306>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.003516723662299084,0.2576587230225311,0.0025074727671450013> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.0037264117646830176,0.25859349703558115,0.0025066707633324306>, <0.003516723662299084,0.2576587230225311,0.0025074727671450013>, 0.01 open texture{ pigment{ Red } } } }
object{ sphere{ <0.003330301096567201,0.25682646904990003,0.002508210792485> 0.01 texture{ pigment{ Red } } } }object{ cylinder{ <0.003516723662299084,0.2576587230225311,0.0025074727671450013>, <0.003330301096567201,0.25682646904990003,0.002508210792485>, 0.01 open texture{ pigment{ Red } } } }