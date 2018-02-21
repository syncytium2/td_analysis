#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//template for analyzing waves in top graph
// what does it do?
////////////////////////////////////////////////////////////////////////////////
//									FUNCTION *** PERMEABILITY *** from wave name
////////////////////////////////////////////////////////////////////////////////
// assumes wn is peak current at the wave scaled voltage
// SI units : straight outta patchmaster
//
function/S permeability( wn, [rescale] ) //mystr, myvar)
string wn
variable rescale // option scaling factor, default converts amps to picoamps

variable scale
if(paramisdefault( rescale ) )
	scale = 1e12
else
	scale = rescale
endif

variable ipoint = 0, npoints = 0

variable Vm, Zs, S_in, S_out, Texp=31 // SI units, V, charge, concentration in, concentration out, exp temperature in C

variable nonzero = 0.00001 // avoid singularities please

variable absT = -273.15 // degrees C
variable T = Texp - absT

variable F = 96485 // coulombs mol-1
variable R = 8.314 // J mol-1 K-1

variable z = 1

variable FoverRT = F / ( R* T )

variable ai = 145, ao = 3.5 // concentration in and out : : : MUST BE IN MILLIMOLAR !!!!
variable Vrev =0
Vrev = (1/FoverRT) * ln( ao / ai )

string waven=removequotes( wn ), out = ""

WAVE/Z w = $waven

if( waveexists( w ) )
	npoints = numpnts(w)
	out = waven + "_p"	
	duplicate/O w, $out // duplicate to copy scaling, plus DON'T EVER CHANGE SOURCE WAVE !
	WAVE/Z pw = $out
	
	pw = w * (z^2*F*FoverRT) ^-1 * ( 1 - exp( z * FoverRT * (x+nonzero) ) ) / ( (x+nonzero) * ( ao - ai * exp( z * FoverRT * (x+nonzero)) ) )

	wavestats /Z/Q pw
	variable maxperm = V_max
	
	variable quote_g_quote = scale * maxperm * z * F * ao // pg. 109 January 27 2016 lab notebook, scale to pA for QuB
	
	print "### g_max for QuB ###", quote_g_quote
//	duplicate/O w, cw // chord conductance
//	cw = w / ( x - Vrev )
//	print FoverRT, 1/FoverRT,Vrev
else
	print "permeability: failed to locate wave from wavename:", waven	
endif

return out
end


////////////////////////////////////////////////////////////////////////////////
//									FUNCTION *** PERMEABILITY *** from wave name
////////////////////////////////////////////////////////////////////////////////
// assumes wn is peak current at the wave scaled voltage
// SI units : straight outta patchmaster
//
function gmax4qub( wn, [rescale] ) // wn contains the raw permeability as a function of voltage
string wn
variable rescale // option scaling factor, default converts amps to picoamps

variable scale
if(paramisdefault( rescale ) )
	scale = 1e12
else
	scale = rescale
endif

variable ipoint = 0, npoints = 0

variable Vm, Zs, S_in, S_out, Texp=31 // SI units, V, charge, concentration in, concentration out, exp temperature in C

variable nonzero = 0.00001 // avoid singularities please

variable absT = -273.15 // degrees C
variable T = Texp - absT

variable F = 96485 // coulombs mol-1
variable R = 8.314 // J mol-1 K-1

variable z = 1

variable FoverRT = F / ( R* T )

variable ai = 145, ao = 3.5 // concentration in and out : : : MUST BE IN MILLIMOLAR !!!!
variable Vrev =0
Vrev = (1/FoverRT) * ln( ao / ai )

string waven=removequotes( wn )
variable out = nan

WAVE/Z pw = $waven

if( waveexists( pw ) )

	wavestats /Z/Q pw
	variable maxperm = V_max
	
	out = scale * maxperm * z * F * ao // pg. 109 January 27 2016 lab notebook, scale to pA for QuB
	
	print "### g_max for QuB from permeability ###", wn, out

else
	print "gmax4qub: failed to locate wave from wavename:", waven	
endif

return out
end

//template for analyzing waves in top graph
// what does it do?
////////////////////////////////////////////////////////////////////////////////
//									FUNCTION *** PERMEABILITY ***
////////////////////////////////////////////////////////////////////////////////

function/S permeabilityTG() //mystr, myvar)
string mystr
variable myvar
string wavel=tracenamelist("",";",1) // get the wavelist from the top graph
string waven=removequotes(stringfromlist(0,wavel))
variable iwave=0,nwaves=itemsinlist(wavel)
variable ipoint = 0, npoints = 0

variable Vm, Zs, S_in, S_out, Texp=31 // SI units, V, charge, concentration in, concentration out, exp temperature in C

Vm += 0.00001 // avoid singularities please

variable absT = -273.15 // degrees C
variable T = Texp - absT

variable F = 96485 // coulombs mol-1
variable R = 8.314 // J mol-1 K-1

variable z = 1

variable FoverRT = F / ( R* T )

variable ai=0.145, ao=0.0035 // concentration in and out
variable Vrev =0
Vrev = (1/FoverRT) * ln( ao / ai )

	waven = removequotes(stringfromlist(0,wavel))
	WAVE w = $waven
	npoints = numpnts(w)
	
	duplicate/O w, pw 

	pw = w * (z^2*F*FoverRT) ^-1 * ( 1 - exp( z * FoverRT * x ) ) / ( x * ( ao - ai * exp( z * FoverRT * x) ) )
	
	duplicate/O w, cw // chord conductance
	
	cw = w / ( x - Vrev )

waven += "_p"
duplicate/O pw, $waven


print FoverRT, 1/FoverRT,Vrev

return waven
end