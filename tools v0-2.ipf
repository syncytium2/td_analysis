#pragma rtGlobals=3		// Use modern global access method and strict wave access.
////////////////////////////////////////////////////////////////////////////////
//									uses wavestats to report max(or min) based on sign
// for each trace in active window
////////////////////////////////////////////////////////////////////////////////

macro getMaxCsr(thesign)
variable thesign=1
	string wavelist=tracenamelist("",";",1)
	string wavelet=removequotes(stringfromlist(0,wavelist))
	variable nwaves=itemsinlist(wavelist)
	variable iwave
	variable prepoint=xcsr(A)
	variable postpoint=xcsr(B)
	variable peak = 0,peak_time=0

print "wavename \t peak \t peak time \t average"
	iwave=0
	do
		wavelet=removequotes(stringfromlist(iwave, wavelist))
		wavestats /Q/Z/R=((prepoint), (postpoint)) $wavelet
		peak=0
		peak_time=0
		if(thesign>0)
			peak = V_max
			peak_time=V_maxloc
		else
			peak = V_min
			peak_time=V_minloc
		endif
		print wavelet,"\t",peak,"\t",peak_time,"\t",V_avg
		
		iwave+=1
	while (iwave<nwaves)
end

////////////////////////////////////////////////////////////////////////////////
//									uses wavestats to report max(or min) based on sign
// for each trace in active window
////////////////////////////////////////////////////////////////////////////////

macro getMeanCsr()
variable thesign=1
	string wavelist=tracenamelist("",";",1)
	string wavelet=removequotes(stringfromlist(0,wavelist))
	variable nwaves=itemsinlist(wavelist)
	variable iwave
	variable prepoint=xcsr(A)
	variable postpoint=xcsr(B)
	variable reg2start=xcsr(c),reg2end=xcsr(d)
	
	variable mean1=0,mean2=0

print "wavename \t mean1 \t mean2"
	iwave=0
	do
		prepoint=xcsr(a)
		postpoint=xcsr(b)
		wavelet=removequotes(stringfromlist(iwave, wavelist))
		wavestats /Q/Z/R=((prepoint), (postpoint)) $wavelet
mean1=V_avg
		prepoint=reg2start
		postpoint=reg2end
		wavestats /Q/Z/R=((prepoint), (postpoint)) $wavelet
mean2=v_avg
		print wavelet,mean1,mean2
		iwave+=1
	while (iwave<nwaves)
end

macro csr()
showinfo /cp=1
end


//////////////////////////
//////////////////////////
//////////////////////////
function convertTXT2num()
// get all waves in top graph/table
// convert to num
variable i, n, npts
string twn, nwn
string wl = WaveList("*", ";","WIN:") // all waves in top graph or table

n = itemsinlist( wl )
edit
for( i=0; i<n; i+=1)
	twn = stringfromlist( i, wl )
	WAVE/T tw = $twn
	if( waveexists( tw ) )
		nwn = twn + "n"
		npts = numpnts( tw )
		make/O/N=(npts) $nwn
		WAVE nw = $nwn
		SetScale/P x 0.1,0.1,"ms", nw
		SetScale d 0,0,"pA", nw

		nw = str2num( tw[p] ) 

		appendtotable nw
	endif
endfor

end