#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//
// LOG10 INT FROM PTB
//
// works on all waves in top table
//
//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function/S Log10intFromTimes( wl )
string wl // a list ofwaves containing the spike time information, _ptb or _sct // = WaveList("*", ";","WIN:") // gets list of waves from top graph or table
string wn = stringfromlist(0, wl)

string intwn = intervalsfromtime( wn )

//string sortwn = sortIntervals( intwn )

string logwn = logintervals( intwn ) // sortwn )
string logwl = ""

variable i=0, n = itemsinlist( wl )
do // for( i=0; i< n; i+=1 )
	wn = stringfromlist( i, wl )
	intwn = intervalsfromtime( wn )
	logwn = logintervals( intwn )
	logwl += logwn + ";"
	i += 1
while( i < n ) // endfor

return logwl
end

//
// LOG10 INT FROM PTB
//
// works on all waves in top table
//
//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
macro Log10intFromPTB( )
string wl = WaveList("*", ";","WIN:") // gets list of waves from top graph or table
string wn = stringfromlist(0, wl)

string intwn = intervalsfromtime( wn )

//string sortwn = sortIntervals( intwn )

string logwn = logintervals( intwn ) // sortwn )
string logwl = ""

variable binzero=-2
variable nbins=400
variable binsize=0.01 //25

variable i=0, n = itemsinlist( wl )
do // for( i=0; i< n; i+=1 )
	wn = stringfromlist( i, wl )
	intwn = intervalsfromtime( wn )
	logwn = logintervals( intwn )
	logwl += logwn + ";"
	i += 1
while( i < n ) // endfor

print burstHistoFunction( logwl, binzero, nbins, binsize )

endmacro
//
// BURSTANALYSIS
//
//
//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
//macro burstanalysisWN( burstWinMin, burstWinMax, burstWinInterval )
//variable burstWinMin=0.01
//prompt burstwinmin, "Burst window start (sec):"
//variable burstWinMax=5
//prompt burstwinmax, "Burst window max (sec):"
//variable burstWinInterval=0.05
//prompt burstWinInterval, "Interval (sec):"
//
//string wl = WaveList("*", ";","WIN:") // gets list of waves from top graph or table
//string wn = stringfromlist(0, wl)
//
//variable bw = 0.5
//string bursts = "", bpx="", bpy=""
//
//string bw_wn = "bw"
//
//make/O/N=(4) bww
////WAVE bw = $bw_wn
//
//bww[0]= 0.1
//
//bww[1]= 0.5
//bww[2]= 1.0
//bww[3]= 5.0
//
//string junk = vbanalysis(wn, burstwinmin, burstwinmax,burstwininterval, bw_wn = "bww")
//
//string citywn = stringbykey( "city", junk )
//
//displayCity( "",  citywn )
//
//end

//
// BURSTANALYSIS
//
//
//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
//macro burstanalysis( burstWinMin, burstWinMax, burstWinInterval )
//variable burstWinMin=0.01
//prompt burstwinmin, "Burst window start (sec):"
//variable burstWinMax=5
//prompt burstwinmax, "Burst window max (sec):"
//variable burstWinInterval=0.05
//prompt burstWinInterval, "Interval (sec):"
//
//string wl = WaveList("*", ";","WIN:") // gets list of waves from top graph or table
//string wn = stringfromlist(0, wl)
//
//variable bw = 0.5
//string bursts = "", bpx="", bpy=""
//
//string junk = vbanalysis(wn, burstwinmin, burstwinmax,burstwininterval)
//
//string citywn = stringbykey( "city", junk )
//
//displayCity( "",  citywn )
//
//end
//
// BURSTHISTO
//
//
//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
//macro burstHisto( binzero, nbins, binsize )
//variable binzero=0
//prompt binzero, "Histo bin window start (sec):"
//variable nbins=100
//prompt nbins, "Nbins:"
//variable binsize=0.25
//prompt binsize, "Bin size (sec):"
//
//string wl = WaveList("*", ";","WIN:") // gets list of waves from top graph or table
//string wn = stringfromlist(0, wl)
//
//print burstHistoFunction( wl, binzero, nbins, binsize )
//end


// WAVE SHUFFLE
//
//
//
//|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
macro waveshuffle( monte )
variable monte = 100

string wl = WaveList("*", ";","WIN:") // gets list of waves from top graph or table
string wn = stringfromlist(0, wl)

variable bw = 0.5
string bursts = "", bpx="", bpy=""

// make intervals
string iwn="", shufflewn="", twn=""

iwn = intervalsFromTime( wn )

shufflewn = shuffletd( iwn )

twn = timefromintervals( shufflewn )

end

/////////////////////////////////////////////////
function/s displayCity( target, citywn )
string target // hostname#graphname, empty string for new graph display
string citywn // name of text wave containing x and y waves for burst city plot

// clean the target

// break out the wave names
WAVE/Z/T cityw = $citywn
variable ibw = 0, nbw = dimsize( cityw, 0 )
string bpxwn="", bpywn=""

//edit/k=1 cityw
if( strlen( target ) == 0 )
	display/k=1 //bpyw vs bpxw
else
	setactivesubwindow $target
endif

ibw = 0	
do	

	bpxwn = cityw[ ibw ][ 0 ] 	//= bpx
	bpywn = cityw[ ibw ][ 1 ] 	//= bpy 

	WAVE bpxw = $bpxwn
	WAVE bpyw = $bpywn

	if( waveexists( bpxw ) )
		appendtograph/R bpyw vs bpxw
		//display/k=1 bpyw vs bpxw
		//SetAxis/A/R right
		modifygraph rgb($bpywn)=(0,0,0)
		ModifyGraph lsize=4
	//	appendtotable bdsw
	endif

	ibw += 1 
while( ibw < nbw )

SetAxis/A/R right

end


/////////////////////////////////////////////////
function/s bursthistofunction( wl, binzero, nbins, binsize )
string wl
variable binzero, nbins, binsize

string wn = ""

variable iw = 0, nw =itemsinlist( wl )
string bursts = "", bpx="", bpy=""
string hwn = ""
variable ih = 0
for(iw=0;iw<nw;iw+=1)
	wn = stringfromlist( iw, wl )
	WAVE w = $wn
	if( numpnts( w ) > 0 )
		hwn = wn+"_h" + num2str(1000*binsize)
		Make/N=(nbins)/O $hwn	
		WAVE hw = $hwn
		Histogram/B={binzero,binsize,nbins} w,hw
		if( ih == 0 )
			 display/K=1 hw
			 Label left "count"
			Label bottom "log10 interval ( log secs )"
		else
			appendtograph hw
		endif
		 ih += 1
	else
		print "no data in: ", wn
	endif
endfor
rainbow()
end

////////////////////////////////////////
//
//  VARY BURST WINDOW ANALYSIS
//
// wrapper function to drive banalysis over a range of burst windows
// 	== returns a vast keyed string of output waves 
//	== version 0-5 moves graphing and tabling of data to the handler / calling routine 
//			for use in panels
//
// 20170111 added option to force name of output, instead of breaking down wn
//
////////////////////////////////////////
function/s vbanalysis(wn, bstart, bend, bdelta, [ bw_wn, force_name ] )
string wn 						// a wave containing the times of the events
variable bstart, bend, bdelta		// first bw, last bw, delta bw
string bw_wn					// optional wave name of wave containing specific bw
string force_name 				// optional to force the name of the output

string bursts="", bpx="", bpy="", bds=""
variable bw=0

// output of banalysis
//output = "bpx:"+bpx+";"+"bpy:"+bpy+";" + "bds:" + bds + ";" 
//output += "bn:" + num2str( nbursts )							// bn :  BURST NUMBER
//output += "mbd:" + num2str( burstduration )					// mbd:  MEAN BURST DURATION
//output += "spb:" + num2str( nspikesperburst ) 					// spb : SPIKES PER BURST
//output += "bf:" + num2str(burstfrequency)
//output += "ssn:" + num2str( nss )
//output += "ssf:" + num2str( ssfreq )
//output += "tf:" + num2str( totalfreq )
//output += "mInter:" + num2str( averageINTEReventinterval )
//output += "mIntra:" + num2str( averageINTRAeventinterval )

variable ibw=0, nbw=0

//
// handle optional params
//
if( paramisdefault( bw_wn ) )
	nbw = ceil( ( bend - bstart ) / bdelta )+1
else
// get the specified burst windows from the wave
	WAVE/Z bw_w = $bw_wn
	if( !waveexists( bw_w ) ) // if wave doesn't exist, abort
		abort
	endif
	nbw = numpnts( bw_w )
endif

variable nanalysis = nbw // ceil ( ( bend - bstart ) / bdelta ) + 1

string shortwn = datecodefromanything( wn ) + "s" + num2str( seriesnumber( wn ) )

if( !paramisdefault( force_name ) )
	shortwn = force_name
endif

string bwwn = shortwn + "_bww"
string bnwn = shortwn + "_bn"
string mbdwn = shortwn + "_mbd"
string spbwn = shortwn + "_spb"
string bfwn = shortwn + "_bf"
string ssnwn = shortwn + "_ssn"
string ssfwn = shortwn + "_ssf"
string tfwn = shortwn + "_tf"
string minterwn = shortwn + "_inter"
string mintrawn = shortwn + "_intra"

make/O/N=(nanalysis) $bwwn, $bnwn, $mbdwn, $spbwn, $bfwn, $ssnwn, $ssfwn, $tfwn, $minterwn, $mintrawn
WAVE bww = $bwwn
WAVE bn = $bnwn
WAVE mbd = $mbdwn
WAVE spb = $spbwn
WAVE bf = $bfwn
WAVE ssn = $ssnwn
WAVE ssf = $ssfwn
WAVE tf = $tfwn
WAVE minter = $minterwn
WAVE mintra = $mintrawn

bww = nan
bn=nan
mbd=nan
spb=nan
bf=nan
ssn=nan
ssf=nan
tf=nan
minter=nan
mintra=nan

// this is a 3 column text wave to store the cityscape data "bpx" and "bpy" and burst durations "bds"
string citywn = shortwn + "_city"
make/T/O/N=(nanalysis, 3) $citywn 
WAVE/T cityw = $citywn
cityw = ""

// output keyed string
string outstr = ""
outstr += "city:" + citywn + ";"
outstr += "bww:" + bwwn + ";"
outstr += "bn:" + bnwn + ";"
outstr += "mbd:" + mbdwn + ";"
outstr += "spb:" + spbwn + ";"
outstr += "bf:" + bfwn + ";"
outstr += "ssn:" + ssnwn + ";"
outstr += "ssf:" + ssfwn + ";"
outstr += "tf:" + tfwn + ";"
outstr += "inter:" + minterwn + ";"
outstr += "intra:" + mintrawn + ";"

ibw = 0
//for(bw=bstart;bw<bend;bw+=bdelta) // loops over a range of burst window durations
for( ibw = 0; ibw < nanalysis; ibw += 1 )

	if( paramisdefault( bw_wn ) )
		bw = bstart + bdelta*ibw
	else
		bw = bw_w[ ibw ]
	endif

	//\\//\\//\\//\\//\\//\\//\\
if( paramisdefault( force_name ) )
	bursts = banalysis( wn, bw ) // this is where the action is at, all the rest is data management// returns a keyed string
else
	bursts = banalysis( wn, bw, force_name = force_name ) // this is where the action is at, all the rest is data management// returns a keyed string
endif
	//\\//\\//\\//\\//\\//\\//\\

// bursts is a keyed string containing either wave names of detailed analyses, or single number summary data (used below)

	bpx = stringbykey("bpx", bursts) // wave name 
	bpy = stringbykey("bpy", bursts) // wave name
	bds = stringbykey("bds", bursts) // wave name
	
	//cityw is a text array of wavenames
	
	cityw[ ibw ][ 0 ] = bpx
	cityw[ ibw ][ 1 ] = bpy 
	cityw[ ibw ][ 2 ] = bds // list of all burst durations for this burst window

	// these waves contain the summary data of detected bursts for each burst window duration
	bww[ibw] = bw
	bn[ibw] = str2num( stringbykey( "bn", bursts ) )
	mbd[ibw] = str2num( stringbykey( "mbd", bursts ) )
	spb[ibw] = str2num( stringbykey( "spb", bursts ) )
	bf[ibw] = str2num( stringbykey( "bf", bursts ) )
	ssn[ibw] = str2num( stringbykey( "ssn", bursts ) )
	ssf[ibw] = str2num( stringbykey( "ssf", bursts ) )
	tf[ibw] = str2num( stringbykey( "tf", bursts ) )
	minter[ibw] = str2num( stringbykey( "mInter", bursts ) )
	mintra[ibw] = str2num( stringbykey( "mIntra", bursts ) )
	
endfor

return outstr // keyed string of all the stored waves

end

////////////////////////////////////////////
////////////////////////////////////////////
////////////////////////////////////////////
//
// detailed burst analysis of a single wave 
//
////////////////////////////////////////////
// rev 0-1 now stores all the durations _bds, accesss key: "bds"
//
////////////////////////////////////////////
function/S banalysis( wn, burstwindow, [ notable, force_name ] )
string wn //  wn is the name of a single wave of event times // OLD: a list of waves to analyze, each wave is a list of spike times
variable burstwindow // the time window to detect bursts
variable notable
string force_name // over rides autoname from wn
//variable start_time, end_time // the start time and end time of the wave to analyze

variable duration = 0, recduration = 0, gapduration = 0 
variable burstTime = burstwindow // original parameter
variable msecConversion = 1
 
variable nresults = 10 
variable npoints = 0

variable numIntraIntervals = 0
variable numInterIntervals = 0
variable numEvents = 0, nss=0

variable idataset=0, ipoint = 0, iInter = 0, iintra = 0
//variable inter_intervals = 0, intra_intervals = 0
variable burstSpikeNumber = 0, burstNumber = 0,  ssNumber = 0, burstDurationTotal = 0
variable lastEvent=0, nEvents=0, nintervals=0
variable burstDuration = 0,  nspikesPerBurst = 0
variable burstFrequency =0, singleSpikeFrequency = 0, totalFrequency = 0, averageInterEventInterval = 0
variable averageIntraEventInterval = 0, burstNumber5min = 0, ssNumber5min = 0
variable iburststart=0, iburstend=0, iburst = 0, nbursts = 0
variable count=0, thisInterval =0

string basename = "", fullname="", datecodestr="", seriesnstr="", expletter=""
string regExp = "([[:digit:]]+)([[:alpha:]])g1s([[:digit:]]+)*"

fullname = wn //stringfromlist( idataset, wlist ) //basename
//splitstring/E=(regExp) fullname, datecodestr, expletter, seriesnstr
string parser =  parsewnGREP( fullname )
datecodestr = stringbykey( "datecode", parser )
expletter = stringbykey( "letter", parser )
seriesnstr = stringbykey( "series", parser )
//print fullname, datecodestr, expletter, seriesnstr
string guess = datecodestr + ";" + expletter + ";"

basename = datecodestr + expletter + "s" + seriesnstr

//20170112
if( !paramisdefault( force_name) )
	basename = force_name
endif

string datasetname = "", spikeinfoname=""

	// datasetName is the name of a wave containing the peak time base, a list of times of events in a raw data wave
	// this is provided by the user analysis of the raw data BEFORE accessing this routine
	
	datasetName = wn // stringfromlist( idataset, wlist )
	WAVE dataset = $datasetname

	if( waveexists( dataset ) )
		
		duration = wnoteduration( datasetname ) //, guess = guess )
		recduration = wnoteVarByKey( datasetname, "RECDURATION" )
		gapduration = wnoteVarByKey( datasetname, "GAPDURATION" )
		
		npoints = numpnts( dataset ) 
		//clean and redimension; sometimes there are trailing zeros and other crap in the _ptb
		count = 0
		for( ipoint = 0; ipoint< npoints ; ipoint+=1 )
			if( dataset[ipoint] >0 )
				count += 1
			endif
		endfor		
		redimension/N=(count) dataset
		npoints = count
		
		// make wave to store info
		spikeinfoname = datasetname + "_inf"
		duplicate/O dataset, $spikeinfoname
		WAVE spikeinfo = $spikeinfoname
		spikeinfo = 0 // = 0 if single spike; = 1 if in burst

		nintervals = npoints-1 //- 1 // last point has no interval
		// get the intervals from spike times in dataset
		make/O/N=( nintervals ) intervals 
		make/O/N=( nintervals ) inter_Intervals // interburst events; events between bursts
		make/O/N=( nintervals ) intra_Intervals // intraburst events; events in bursts
		make/O/N=( nintervals ) burstStarts
		make/O/N=( nintervals ) eventStarts
		
		make/O/N=( npoints ) sspoints, ssTimes
		make/O/N=( npoints ) burstpoints, burstTimes, burstDurations, burstSpikes		
		
		// initialize all waves
		intervals = nan
		inter_intervals = nan
		intra_Intervals = nan
		burstStarts = nan
		eventStarts = nan
		sspoints = nan
		sstimes = nan
		burstpoints = nan
		bursttimes = nan
		burstdurations = nan
		burstspikes = 1  // all bursts have more than one spike, by definition
		
		// store the burst times for plot
		// 20170111 was 10000, now 2*npoints
		make/O/N=(2*npoints) burstplotx, burstploty // set to NaN if single spike
		burstplotx = nan
		burstploty = nan
		variable ibp = 0
		
		// calculate the intervals from the peak times stored in dataset
		for( ipoint = 0; ipoint< nintervals ; ipoint+=1 )
			intervals[ ipoint ] = dataset[ ipoint+1 ] - dataset[ ipoint ] // forward difference, last point has no interval
		endfor

		numInterIntervals = 0
		iInter = 0	// inter for intervals between single spikes
		numIntraIntervals = 0
		iIntra = 0	// intra for intervals within a burst
		iburst = 0	// count the bursts
		nbursts = 0
		nss = 1
 		// loop over intervals to 
 		//eventStarts[0]=0
		for( ipoint = 0; ipoint < nintervals; ipoint +=1 ) // this is a loop over all the intervals
			// interval is the time to the next spike
			if( Intervals[ ipoint ]  > burstwindow ) 		// if the interval is greater than the burstwindow, event is a single spike

				ibp +=1
				
				sspoints[ iinter ] = ipoint 						// count the single spikes
				ssTimes[ iinter ] = dataset[ ipoint ] 				// store the single spike times
				inter_intervals[ iinter ] = intervals[ ipoint ] 	// store the single spike intervals
				iinter += 1
				nss +=1 // counting the number of single spikes
				
			else // burst detected ! 
				
				burstpoints[ iintra ] = ipoint // stores first burst spike index
				burstTimes[ iintra ] = dataset[ ipoint ] // stores first spike time
				burstdurations[ iburst ] = 0

				do // loop until the burst is over, with an interval > burstTime

					burstplotx[ ibp ] = dataset[ ipoint ]
					burstploty[ ibp ] = burstwindow
					burstplotx[ ibp+1 ] = dataset[ ipoint+1 ]
					burstploty[ ibp+1 ] = burstwindow
					ibp += 1				

					spikeinfo[ ipoint ] = 1
					burstdurations[ iburst ] += intervals[ ipoint ] // add up the intervals for burst duration
					burstspikes[ iburst ] += 1 // count the number of spikes in the burst
					intra_intervals[ iIntra ] = intervals[ ipoint ]
					ibp += 1
					iIntra += 1
					ipoint += 1 // move counter forward to next spike
				while( ( ipoint < nintervals ) && ( intervals[ ipoint ] < burstTime ) )
				//end the burst plot
				ibp += 1
				iburst += 1
				
				// last spike is in burst, but interval goes into inter
				if( ipoint < nintervals )
					inter_intervals[ iinter ] = intervals[ ipoint ] 
					iinter += 1
				endif

			endif
		endfor

		numinterintervals = iinter
		numintraintervals = iintra
		numEvents = numInterIntervals + 1
		nbursts = iburst
		//nss = iinter - nBursts // the spike ending bursts is not a single spike!

		redimension/N=( numinterintervals ) inter_intervals
		redimension/N=( numinterintervals ) eventstarts
		redimension/N=( numintraintervals ) intra_intervals, burstpoints, bursttimes
		redimension/N=( nbursts ) burstdurations, burstspikes
		
		//print datasetname, nbursts, nss
		
		if( nbursts >0)
			wavestats/Z/Q burstdurations
			burstDuration = V_avg
			wavestats/Z/Q burstspikes
			nspikesPerBurst = V_avg
			if( nbursts == 1)
				burstduration = burstdurations[0]
				nspikesperburst = burstspikes[0]
			endif
			burstFrequency = nbursts / recduration*msecConversion
			burstNumber5min = nbursts / duration*300
			ssNumber5min = nss / duration*300
		else
			burstDuration = nan
			nspikesPerBurst = nan
			burstFrequency = nan
			burstNumber5min = nan
			ssNumber5min = nan
		endif
				 
		singleSpikeFrequency = nss / recduration * msecConversion
		totalFrequency = npoints / recduration * msecConversion
		averageInterEventInterval = mean(inter_Intervals)
		averageIntraEventInterval = mean(intra_Intervals)				 
		
	endif // if the dataset actually exists

string output = ""	

//display dummy vs burstplot

string bpx = basename + "_bw_" + num2str(burstwindow) +"_bpx"
string bpy = basename + "_bw_" + num2str(burstwindow) + "_bpy"
string bds = basename + "_bw_" + num2str(burstwindow) + "_bds"
//make/O $bpx, $bpy, $bds
duplicate/O burstplotx, $bpx 
duplicate/O burstploty, $bpy 
duplicate/O burstdurations, $bds

// return a keyed string with results:
output = "bpx:"+bpx+";"+"bpy:"+bpy+";" + "bds:" + bds + ";" 
output += "bn:" + num2str( nbursts ) + ";" 
output += "mbd:" + num2str( burstduration ) + ";" 
output += "spb:" + num2str( nspikesperburst ) + ";" 
output += "bf:" + num2str(burstfrequency) + ";" 
output += "ssn:" + num2str( nss ) + ";" 
output += "ssf:" + num2str( singlespikeFrequency ) + ";" 
output += "tf:" + num2str( totalfrequency ) + ";" 
output += "mInter:" + num2str( averageINTEReventinterval ) + ";" 
output += "mIntra:" + num2str( averageINTRAeventinterval ) + ";" 

return output
end


/////////////////////////
function/s sortintervals( wn )
string wn

string outwn = datecodeGREP2( wn ) + "_s"
duplicate/O $wn, $outwn

WAVE w = $outwn

sort w, w

return outwn

end

/////////////////////////
function/s logintervals( wn )
string wn

string outwn = wn + "_LOG"
duplicate/O $wn, $outwn

WAVE w = $outwn

w = log( w )

return outwn
end

//macro testkeyfunc()
//string test = "key1:0,1;key2:2,3;key3:3,4;"
//
//print nkeys( test )
//print ithkey( 1, test )
//
//string wn = stringfromlist( 0, wavelist("*_sct",";","" ) )
//variable bs=1, be=60, bd=1
//string regions_str = test
//print vbanalysis( wn, bs, be, bd, regions_str = test )
//
//endmacro

// region handler
function /s regionhandler( region_Str ) // returns wave names with names, starts, and ends
string region_str
string names="names", starts="starts", ends="ends"

variable nregions = 0, i=0

	//if( paramisdefault( regions_str ) )
	
	//else
		nregions = nkeys( region_str )
		make/N=(nregions)/O/T $names
		wave/T region_names = $names 
		make/N=(nregions)/O $starts
		wave region_starts = $starts
		make/N=(nregions)/O $ends
		wave region_ends = $ends 
		for( i = 0 ; i < nregions ; i += 1 )
			region_names[ i ] = ithkey( i+1, region_Str )
			string temp = stringbykey( region_names[ i ], region_str ) 
			region_starts[ i ] = str2num( stringfromlist( 0, temp, "," ) )
			region_ends[ i ] = str2num( stringfromlist( 1, temp, "," ) ) 
		endfor
	//endif
	
	string outstr = "names:" + names + ";" + "starts:" + starts + ";" + "ends:" + ends + ";"
return outstr
end


// keyed string info routines
function/S ithkey( ith, keyedstr, [ keydelimiter, itemdelimiter, keyseparator ] )
variable ith // 1-based number of the desired key
string keyedstr // keyed string
string keydelimiter, itemdelimiter, keyseparator // info on strucutre
// key dellmiiter defaults to ":" colon
// item delimiter "," comma 
// separator ";" semicolon

string keydel = ":", itemdel = ",", keysep = ";" // defaults
if ( !paramisdefault( keydelimiter ) )
	keydel = keydelimiter
endif
if ( !paramisdefault( itemdelimiter ) )
	itemdel = itemdelimiter
endif
if ( !paramisdefault( keyseparator ) )
	keysep = keyseparator
endif

// find all the keydels
variable i=0, pos=0, startpos = 0, endpos = 0
string ithkey = ""
do
	pos = strsearch( keyedstr, keydel, pos ) + 1

	if (pos > 0 ) // the key delimiter is found
		i+=1
		if ( i == ith )
			endpos = pos-2
			startpos = strsearch( keyedstr, keysep, pos, 1) + 1 //backwards
			ithkey = keyedstr[ startpos, endpos ]
		endif	

	endif

	//print keyedstr, keydel, pos, ithkey
while( pos > 0 )
// to the left are the keys
// to the right are items
return ithkey
end	 // return ith key


function nkeys( keyedstr, [ keydelimiter, itemdelimiter, keyseparator ] )
string keyedstr // keyed string
string keydelimiter, itemdelimiter, keyseparator // info on strucutre
// key dellmiiter defaults to ":" colon
// item delimiter "," comma 
// separator ";" semicolon

string keydel = ":", itemdel = ",", keysep = ";" // defaults
if ( !paramisdefault( keydelimiter ) )
	keydel = keydelimiter
endif
if ( !paramisdefault( itemdelimiter ) )
	itemdel = itemdelimiter
endif
if ( !paramisdefault( keyseparator ) )
	keysep = keyseparator
endif

// find all the keydels
variable i=0, pos=0
do
	pos = strsearch( keyedstr, keydel, pos ) + 1
	//print keyedstr, keydel, pos
	if (pos > 0 )
		i+=1
	endif
while( pos > 0 )
// to the left are the keys
// to the right are items
return i
end	