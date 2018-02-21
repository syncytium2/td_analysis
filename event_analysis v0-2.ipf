#pragma TextEncoding = "Windows-1252"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// functions for analyzing a single event, like a PSP or PSC. Gets wavenames from top graph

// 20170707 cleaned up, commented

// copy this macro, rename, save to a different procedure file! 
// and modify parameters for specific analysis situations
//
// WARNING :: OVERWRITES RESULTS TABLE EACH RUN !!!
//
//  \\//\\//\\//\\//\\//\\//\\//\\


//\\//\\//\\//\\//\\//\\//\\//\\
//  \\//\\//\\//\\//\\//\\//\\//\\

// template for analyzing waves in top graph
// what does it do? analyzes waveforms // was just for depolarizing psps
// new version 20151008
// newer version 20170706 now with area!
//		uses graph axes to set baseline and analysis range: use_csr = -1
// 20171011 now returns string of analysis waves. waves can be named via optional param
//
////////////////////////////////////////////////////////////////////////////////
//									FUNCTION eventM (event measure) version INF ! ! !
////////////////////////////////////////////////////////////////////////////////

function/s eventM( m_rin, use_csr, [ tr, bsl, xs, xe, xinc, pwin, psign, name, tablen, maxseries ] ) //m_rin=1 if measure input resistance, else nope; use_csr=1 if use csr
variable m_rin, use_csr, tr, bsl, xs, xe, xinc, pwin, psign
string name // user optional string to name waves
string tablen // user optional string name of table to create / append results
variable maxseries

string wavel = tracenamelist("",";",1), prefix = ""
string waven = removequotes(stringfromlist(0,wavel))
variable iwave=0, nwaves=itemsinlist(wavel), tn=0
string outlist = ""
make/O w_coef

variable imax = inf

if(paramisdefault(maxseries))
	imax = inf
else
	imax = maxseries
endif

if( paramisdefault( name ) )
	make/T/O/N=(nwaves) pspwn
	make/O/N=(nwaves) pspbaseline
	make/O/N=(nwaves) psprelamp
	make/O/N=(nwaves) pspder
	make/O/N=(nwaves) pspabsamp
	make/O/N=(nwaves) psprin
	make/O/N=(nwaves) pspmemtau
	make/O/N=(nwaves) psp1090
	make/O/N=(nwaves) psp2080
	make/O/N=(nwaves) pspFWHM
	make/O/N=(nwaves) pspDecTau
	make/O/N=(nwaves) pspMaxLoc
	make/O/N=(nwaves) pspArea
	make/O/N=(nwaves) pspRiseT50
	make/O/N=(nwaves) pspRise1090
	make/O/N=(nwaves) pspbsl2
	
	outlist = "pspwn;pspbaseline;pspabsamp;psprelamp;pspder;psprin;pspmemtau;psp1090;psp2080;pspFWHM;pspDecTau;pspMaxLoc;pspArea;pspRiseT50;pspRise1090;pspBsl2"

else
	if( strlen( name ) <= 1 )
		name += datecodefromanything( waven ) + "s" + num2str( seriesnumber( waven ) )
		print "eventM: optional autoname:", name
	endif
	prefix = name

	string twn = name + "wn"
	outlist += twn + ";"
	make/T/O/N=(nwaves) $twn ////= { "" }
	WAVE/T pspwn = $twn

	twn = name + "bsl"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn ////= { nan }
	WAVE pspbaseline = $twn

	twn = name + "rpk"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE psprelamp = $twn

	twn = name + "der"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE pspder = $twn
	
	twn = name + "apk"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan } 
	WAVE pspabsamp = $twn
	
	twn = name + "rin"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE psprin = $twn
	
	twn = name + "mTau"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE pspmemtau = $twn

	twn = name + "1090"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE psp1090 = $twn
	
	twn = name + "2080"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE psp2080 = $twn
	
	twn = name + "FWHM"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE pspFWHM = $twn
	
	twn = name + "dTau"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE pspdectau = $twn
	
	twn = name + "maxLoc"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE pspMaxLoc = $twn
	
	twn = name + "area"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE pspArea = $twn
	
	twn = name + "rT50"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE pspriseT50 = $twn
	
	twn = name + "r1090"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE psprise1090 = $twn
	
	twn = name + "bsl2"
	outlist += twn + ";"
	make/O/N=(nwaves) $twn //= { nan }
	WAVE pspBSL2 = $twn	
endif

variable xstart = -inf, xend = inf
if( !paramisdefault( xs ) )
	xstart = xs
	xend = xe
endif

//cursors 
switch(use_csr)
	case 1:
		if(strlen(csrinfo(A))==0)
			showinfo
			print "please place cursors"
			abort
		endif
		xstart=xcsr(A)
		xend=xcsr(B)
		break;
	case -1: // error checking?
		getAxis/Q bottom
		xstart = V_min
		xend = V_max
		break;
	default:
		break;
endswitch
if(xstart==xend)
	xstart = -inf
	xend = inf
endif

variable rstart = 0.01,rend = 0.11,Irin = -5e-12 //this is current for Rin pulse, pA!
variable base=0.005,awave=0,peaktime=0

variable bstart = 0, bend = 0
if(paramIsDefault(bsl))
	bstart = xstart
	bend = bstart + base
else
	bstart = bsl
	bend = bsl + base	
endif

variable pstart = 0, pend = 0
if(paramIsDefault(pwin))
	pstart = xstart
	pend = xend
else
	pstart = xstart
	pend = xstart + pwin	
endif

variable V_FitError = 0, V_fitquitreason = 0

do
//get baseline 5 msec to right of cursor A OR xstart
	waven=removequotes(stringfromlist(iwave,wavel))
	
	if( paramIsDefault( tr ) )
		tn = tracenumber( waven ) // tn_option not set, analyze all traces
	else
		tn = tr // tn_option sets the tracenumber for analysis
	endif
	
	if( tracenumber( waven ) != tn ) // ignore if not the correct trace
		iwave+=1
	else

		if( xstart >= xend )
			print "eventM: xstart >= xend: xinc", xstart, xend, xinc
		else
			//print "xstart < xend: xinc", xstart, xend, xinc

			pspwn[awave]=waven
			WAVE bslw = $waven
			wavestats /Q/Z/R=(bstart, bend) bslw
			pspbaseline[awave] = V_avg * 1000
			wavestats /Q/Z/R=(xstart-0.005, xstart) bslw
			pspbsl2[awave] = V_avg * 1000			
			duplicate/O/R=(xstart,xend) $waven, w
			
			//wavestats /Q/R=(0, base) /Z w
			//pspbaseline[awave] = V_avg
			wavestats /Q/Z/R=(pstart, pend) w
			
			variable thissign = -1 
			if( !paramisdefault( psign ) )
				thissign = psign
			endif
			
			differentiate w /D=dw
			
			if( thissign > 0 ) // positve peak
				
				peaktime = V_maxloc
				pspMaxLoc[awave] = (V_maxloc - pstart) * 1000
				pspabsamp[awave] = V_max * 1000 //assuming depolariizng!
				thissign = 1
	
				wavestats /Q/R=(xstart, xend) /Z dw
				pspder[awave] = V_max //assuming depolariizng!
	
			else
	
				peaktime = V_minloc
				pspMaxLoc[awave] = (V_minloc - pstart) * 1000
				pspabsamp[awave] = V_min * 1000
				thissign = -1
	
				wavestats /Q/R=(xstart, xend) /Z dw
				pspder[awave] = V_min 
				
			endif 
					
			psprelamp[awave] = pspabsamp[awave]-pspbaseline[awave]
			
			if(m_rin) // cc mode passive properties
				WAVE rw = $waven
				wavestats/Q/R=(rend,rend-base) /Z rw
				psprin[awave]=V_avg
				wavestats/Q/R=(rstart,rstart+base) /Z rw
				psprin[ awave ] -= V_avg
				psprin[ awave ] /= irin
				psprin[ awave ] *= 1e-6 // megaohms

				V_FitError = 0
				V_fitquitreason = 0
				CurveFit/Q/N exp_XOffset, rw( rstart, rend ) // /D	
				pspmemtau[ awave ] = W_coef[2]	* 1000

				V_FitError = 0
				V_fitquitreason = 0
				CurveFit/Q/N exp_XOffset, rw( rend, rend + (rend-rstart) )  // /D	
				pspmemtau[awave] += w_coef[2] * 1000
				pspmemtau[awave] /= 2
			endif
	
	// kinetics means time course
		// subtrace baseline from chopped wave
			w -= 0.001 * pspbaseline[awave]
	// 10-90
			psp1090[awave] = return1090Decay3( "w", thissign, 3 ) * 1000
	// 20-80
			psp2080[awave] = return2080Decay3( "w", thissign, 3 ) * 1000
	// FWHM
			pspFWHM[awave] = returnFWHM3( "w", thissign, 3 ) * 1000
	// tauDecay
			//pspDecTau[awave] = returnDecTauZ( "w", thissign, 3 )
			pspDecTau[awave] = returnDecTau( "w", thissign, 3 ) * 1000
	// area 20170707
			pspArea[ awave ] = area( w, xstart, xend ) // assumes baseline is zero, integrates full range
	// t50 rise
			pspRiseT50[ awave ] = risetimeT50( "w", 0.001 * psprelamp[awave], peaktime, 0.001 * psprelamp[awave], thissign ) * 1000 //, show=1 )		
			pspRise1090[ awave ] = risetime1090( "w", 0.001 * psprelamp[awave], peaktime, 0.001 * psprelamp[awave], thissign ) * 1000 //, show=1 )		
			
			awave+=1
			
			if( !paramisdefault( xinc ) )
				xstart += xinc
				pstart = xstart // += xinc
				pend = xstart + pwin
			endif
		endif // xstart < xend					
		iwave+=1

	endif
while( ( iwave < nwaves ) && ( iwave < imax ) )

redimension/N=(awave) pspwn
redimension/N=(awave) pspbaseline
redimension/N=(awave) psprelamp
redimension/N=(awave) pspder
redimension/N=(awave) pspabsamp
redimension/N=(awave) psprin
redimension/N=(awave) pspmemtau
redimension/N=(awave) psp1090
redimension/N=(awave) psp2080
redimension/N=(awave) pspFWHM
redimension/N=(awave) pspDecTau
redimension/N=(awave) pspMaxLoc
redimension/N=(awave) pspArea
redimension/N=(awave) pspRiseT50
redimension/N=(awave) pspRise1090
redimension/N=(awave) pspbsl2

if( paramisdefault( tablen ) )
	doWindow/K results
	edit/N=results/K=1 pspwn,pspbaseline, pspabsamp, psprelamp,pspder,psprin,pspmemtau,psp1090,psp2080,pspFWHM,pspDecTau, pspMaxLoc, pspArea, pspRiseT50, pspRise1090, pspBSL2
else
	// see if the table already exists
	dowindow/F $tablen
	if( V_flag == 1 )
		// if it does, append
	else
		edit/N=$tablen/K=1
		// if it does not, create tablen	
	endif
	appendtotable/W=$tablen pspwn,pspbaseline, pspabsamp, psprelamp,pspder,psprin,pspmemtau,psp1090,psp2080,pspFWHM,pspDecTau, pspMaxLoc, pspArea, pspRiseT50, pspRise1090, pspBSL2
endif	
	
string wavenames = outlist
return wavenames
end

// end psp meassure vINF 20151008 // mod 20170706 neg peaks option


// mod 20170926 decay tau function
//////////////////////////
// return 2080 decay TAU // modified 
//////////////////////////
function returnDecTauZ(waveletS,thissign,nsmooth)
string waveletS; variable thissign,nsmooth
variable peak,peaktime
if (!waveexists($waveletS))
	return -1
	abort
endif
WAVE mywavelet=$waveletS
duplicate/O mywavelet, wavelet

Smooth /B=1 nsmooth, wavelet
wavestats /Q wavelet
if (thissign<0)
	peak=V_min
	peaktime=V_minloc
else
	peak=V_max
	peaktime=V_maxloc
endif

variable start_time,end_time,max80,max20,decay2080
variable fall80,fall20

start_time=pnt2x(wavelet,0)			//gets the end of the wave
end_time=pnt2x(wavelet, numpnts(wavelet)-1)			//gets the end of the wave

max80 = 0.9 * peak // 0.8*peak
max20 = 0.1 * peak // 0.2*peak

findlevel /Q/R=(peaktime,end_time) wavelet,max80
IF(V_flag==0)
	fall80=V_levelX
else
	fall80=nan
//	print "10-90 FAILURE fall90: ",peaktime, end_time, peak, max90
endif

findlevel /Q/R=(peaktime,end_time) wavelet,max20
IF(V_flag==0)
	fall20=V_levelX
else
	fall20=nan
//	print "20-80 FAILURE fall10: ",peaktime, end_time, peak, max10
	//display $wavelet
endif
make/O/N=4 w_coef
variable V_FitError = 0, V_fitquitreason = 0
duplicate/O wavelet, fit_wavelet
fit_wavelet = 0
V_FitError = 0 // suppress errors. too lazy to catch them myself
Curvefit /Q/N exp_Xoffset, wavelet(fall80,fall20) /D=fit_wavelet
//appendtograph fit_wavelet
//ModifyGraph lsize(fit_wavelet)=2,rgb(fit_wavelet)=(0,0,0)
//if( V_fitquitreason == 0 )
//
//else
//	print "failed exp fit, inside measurepeaks", v_fitquitreason, v_fiterror, waveletS
//endif								
//if( numtype( w_coef[2] ) == 2 )
//	print "failed exp fit, inside measurepeaks", v_fitquitreason, v_fiterror, waveletS
//endif
decay2080 = 1/w_coef[2]

return decay2080
end


///////////////\\\\\\\\\\\\\\
function equilibrateTable()
// get the top table
string wlist = winlist("*", ";","WIN:2"), mytable = stringfromlist( 0, wlist ) // win:2 is tables

// get the list of waves
string wavel = wavelist("*", ";", "WIN:" + mytable ) //
variable i=0, n=itemsinlist( wavel ), maxpnts = -inf, pnts = -inf
for( i=0; i< n; i+=1 )
	pnts = numpnts( $stringfromlist( i, wavel ) ) 
	if(  pnts > maxpnts )
		maxpnts = pnts
	endif 
endfor
print "maxpoints: ", maxpnts
// make all the other waves match the biggest wave
for( i=0; i< n; i+=1 )
	redimension/N=(maxpnts) $stringfromlist( i, wavel )
endfor
end
