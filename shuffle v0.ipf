

// WAVE SHUFFLE
//
//
//
//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
macro waveshuffleTD( monte )
variable monte = 100

string wl = WaveList("*", ";","WIN:") // gets list of waves from top graph or table
string wn = stringfromlist(0, wl)

variable bw = 0.5
string bursts = "", bpx="", bpy=""

// make intervals
string iwn="", shufflewn="", twn=""

duplicate/O $wn, shuffled

iwn = "shuffled"  //intervalsFromTime( wn )

shufflewn = shuffletd( iwn )

//twn = timefromintervals( shufflewn )

probdistp( wn, 1 )
probdistp( shufflewn, 1)

string wndist = wn + "_dist"
string shufflewndist = shufflewn + "_dist" 

display $wndist, $shufflewndist

end


//Random (in-place) shuffle of input wave's elements
//Posted July 14th, 2010 by s.r.chinn
//in Utilities 6.12.x
//http://www.igorexchange.com/node/1614

function shuffle(inwave)	//	in-place random permutation of input wave elements
//http://www.igorexchange.com/node/1614
	wave inwave
	variable N	=	numpnts(inwave)
	variable i, j, emax, temp
	for(i = N; i>1; i-=1)
		emax = i / 2
		j =  floor(emax + enoise(emax))		//	random index
// 		emax + enoise(emax) ranges in random value from 0 to 2*emax = i
		temp		= inwave[j]
		inwave[j]		= inwave[i-1]
		inwave[i-1]	= temp
	endfor
end

//|||||||||||||||||||||||||||||| using TD conventions
function/s shuffleTD( wn )
// modified from http://www.igorexchange.com/node/1614
	string wn

	wave inwave = $wn
	string outwaven = wn + "_RND"
	
	duplicate/O inwave, $outwaven
	wave ow = $outwaven
	variable N	=	numpnts(ow)
	variable i, j, emax, temp

	for(i = N; i>1; i-=1)
		emax = i / 2
		j =  floor(emax + enoise(emax))		//	random index
// 		emax + enoise(emax) ranges in random value from 0 to 2*emax = i
		temp		= ow[j]
		ow[j]		= ow[i-1]
		ow[i-1]	= temp
	endfor
	
	//edit/k=1 ow
	return outwaven
end
 
function testShuffle(npts, nshuffles)
//http://www.igorexchange.com/node/1614
	variable npts, nshuffles
	make/O/N=(nshuffles, npts) wave0 = q+1	//	2D  (trials) x (array size)
	make/O/N=(npts) wtemp					//	temporary column (trial) wave
	variable i
	for(i=0; i<nshuffles; i+=1)					//	shuffle each row
		wtemp = wave0[i][p]
		shuffle(wtemp)
		wave0[i][] = wtemp[q]
	endfor
	Make/O/N=(npts) wmean	//	mean of the trials column for each array 'bin'
	for(i=0; i<npts; i+=1)
		MatrixOp/O wdest = col(wave0,i)
		wmean[i] = mean(wdest)	//	in this test, should approach (npts+1)/2
	endfor
end

//|||||||||||||||||||||
function/s intervalsFromTime( wn )
string wn

WAVE w = $wn
string outwn = datecodeGREP( wn ) + "s" + num2str( seriesnumberGREP( wn) ) +  "_i"
if( numtype( seriesnumberGREP( wn) )> 0  )
	outwn= wn+"_i"
endif
//string outwn = wn + "_i"
duplicate/O w, $outwn
WAVE ow = $outwn
ow = nan

variable i=0, n=numpnts(w)
for( i = 0; i < ( n - 1 ); i += 1 )
	ow[ i ] = w[i+1] - w[i]
endfor

return outwn
end

//|||||||||||||||||||||
function/s TimeFromIntervals( wn )
string wn

WAVE w = $wn

string outwn = wn + "_it"
duplicate/O w, $outwn
WAVE ow = $outwn
ow = nan

variable i=0, n=numpnts( w )
ow[ 0 ] = w[ 0 ] 
for( i = 1; i <  n ; i += 1 )
	ow[ i ] = ow[ i-1 ] + w[ i ]
endfor

return outwn
end