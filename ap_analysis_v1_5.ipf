// modified 20121210 to clarify derivative cutoff value and units
// also storing derivative cutoff in the wave note, and
// renaming data arrays based on wavename.


#pragma rtGlobals=1		// Use modern global access method.

function getparam(boxtitle,prompttext,defaultvalue)
	string boxtitle, prompttext
	variable defaultvalue
	variable input=defaultvalue
	prompt input, prompttext
	DoPrompt boxtitle, input
	return input  
end

// sets up prompt for two numeric entries, returns keyed stringlist
// DO NOT PUT COLONS IN PROMPTTEXT! 
function/s get2params(boxtitle,prompttext,defaultvalue,prompttext2,defaultvalue2)
	string boxtitle, prompttext, prompttext2
	variable defaultvalue,defaultvalue2
	variable input=defaultvalue, input2=defaultvalue2
	prompt input, prompttext
	prompt input2, prompttext2
	
	DoPrompt boxtitle, input, input2
	string output = prompttext + ":" + num2str(input) + ";" + prompttext2 + ":" + num2str(input2) + ";"
	return output  
end

function APpropV2_2(trace, smoothing,dthreshold, [disp] )
	variable trace,smoothing,dthreshold
	variable disp // =0 no display, =1 save chunks and display, =2 save chunks and phase planes and display
	
	if(paramisdefault(disp) )
		disp = 0 
	endif
	
	print "appropV2_2"
	variable minslope=dthreshold // AP threshold at 1V/sec
//	variable smoothing=10
//	print "Using minslope = ",minslope,". For GNRH action potentials, this should be 1!"

	variable eoi=1

	string wavelist=tracenamelist("",";",1)
	string dwave,twave,tablelist
	
	string wavelet=stringfromlist(0,wavelist),wavenote
	string apwaven = "", ppwaven = " ", APsuffix = "_AP", PPsuffix = "_PP" //followed by sweep number and ap number, e.g. _AP0112 sweep 1 ap 12

	variable nwaves=0
	variable iwave=0,ispike=0,prevloc=0
	variable threshold=0//=$(wavelet)(xcsr(a))
	variable threshold_time=0,dpeak_time=0
	variable interval,APloc,APamp,APFWHM
	variable AHPamp,AHPFWHM,AHPloc,AHPmin
	variable halfmax0,firsthalf,sechalf
	variable start0,end0,levels0,maxlevels=6000
	variable dAPrisemax,thresholdloc

	variable tablecount=0
	variable frontrange=5e-3, backrange=3e-3 // assumes units are seconds!!!
	variable ahp_offset = 0.02 // look for the AHP minium within 20 msec of AP peak loc
	
	variable basestart=0, baseend=0.005,baseline,estart,eend
	variable Ih_offset=0.1,myspikes=0,thisspike=0,nspikes=0
	variable iprop=0, nprops=12, firstspike=0,offset=0
	variable tstart=0,tstart0=0, align=0
	
	if(trace==-1)
		iwave=0
		nwaves=itemsinlist(wavelist)
	else
		iwave=trace
		nwaves=1
	endif
	
	wavelet=removequotes(removequotes(stringfromlist(iwave,wavelist)))
	tstart0=PMsecs2Igor(acqtime(wavelet))
	
	WAVE waveletZ = $wavelet
	wavenote=note(waveletZ)
//uses whole trace
	estart = leftx(waveletZ)
	eend = rightx(waveletZ)
	
	showinfo
	cursor a, $wavelet, estart
	cursor b, $wavelet,eend
	make /D/N=(maxlevels,nprops)/O alldata
//	WAVE twaveZ = $(twave)
	myspikes=0
	alldata=0
	make /D/N=(nwaves,nprops)/O tracedata
	tracedata=0

	make/D/O/n=(maxlevels) event_abstime
	make/D/O/n=(maxlevels) event_reltime

	make/D/O/n=(nwaves) trace_abstime
	make/D/O/n=(nwaves) trace_reltime

	do //loop over each wave in graph

		wavelet=removequotes(wavelet)
		tstart=PMsecs2Igor(acqtime(wavelet))


		WAVE waveletZ = $wavelet
		wavestats /Q/R=(basestart,baseend) waveletZ
		baseline=V_avg
		twave="t"+wavelet
		dwave="d"+wavelet
//		WAVE waveletZ = $wavelet
		duplicate/O waveletz, $(dwave)
		differentiate $(dwave)
		findlevels /R=(estart,eend)/Q waveletZ,0 //assumes action potentials cross zero!
		levels0=V_levelsFound
		nspikes = levels0/2
		duplicate/O w_findlevels, levelswave
		duplicate/o levelswave, yaxis
		
		yaxis=0
//		appendtograph yaxis vs levelswave
		print iwave, wavelet, nspikes
		if(levels0>0)
		
			ispike=0

			prevloc=0
			interval=0
			thisspike=0
			do // loop over the spikes in current wave
				start0=levelswave[ispike]-frontrange
				end0=levelswave[ispike]+backrange
				wavestats /Q/R=(start0,end0) waveletZ
				if(ispike>0) 
					interval=V_maxloc-prevloc
					prevloc=0 // resets previous location for next spike
				endif
		
				if(V_maxloc!=prevloc)  // reject duplicate spikes!!!	
					prevloc=V_maxloc
					APloc=V_maxloc
					APamp=V_max
					wavestats /Q/R=(start0,end0) $(dwave)
					dpeak_time=V_maxloc
					dAPriseMax=V_max
					if((start0>rightx($(dwave)))%|(dpeak_time>rightx($(dwave))))
						print "ran out of data--spike properties of the edge of recording"
					else
//original				findlevel /b=(smoothing)/Q/R=(start0,dpeak_time) $(dwave), minslope
// now working backwards from dpeak to first crossing of minslope, search out to the previous AP
						findlevel /b=(smoothing)/Q/R=(dpeak_time, 0) $(dwave), minslope
						threshold_time=V_LevelX
						if(v_flag==0) //if the threshold is between the peak of the derivative and the previous spike
							threshold=waveletz(threshold_time)
							APamp-=threshold
							halfmax0=threshold+0.5*APamp
							findlevel /Q/R=(APloc,threshold_time) waveletz, halfmax0
							//+++ find halfmax upside
							if(v_flag==0) // if level is found = halfmax updside
								firsthalf=V_levelX
								findlevel /Q/R=(APloc,aploc+backrange) waveletz, halfmax0
								//xxx find halfmax downside
								if(v_flag==0)	// if level is found = halfmax downside
									if(disp>0)
								// store spike
										apwaven = wavelet + apsuffix + "s"+ num2str( sweepnumber(wavelet) )+ "a"+ num2str( myspikes )
										align = dpeak_time // threshold_time
										duplicate/O/R=(align-frontrange, align + ahp_offset ) waveletz, $apwaven
										WAVE apw = $apwaven
										setscale/P x,  -frontrange, deltax(waveletz), apw
										
										if(myspikes==0) // make display
											display/K=1/N=ActionPotentials0 apw
										else
											appendtograph/W=ActionPotentials0 apw
										endif
								// store phase plane
										if(disp>1) 
											ppwaven = wavelet + apsuffix + "s"+ num2str( sweepnumber(wavelet) )+ "p"+ num2str( myspikes )
											duplicate/O apw, $ppwaven
											WAVE dapw = $ppwaven
											differentiate dapw
											if(myspikes==0) // make display
												display/K=1/N=phase0 dapw vs apw
											else
												appendtograph/W=phase0 dapw vs apw
											endif
										endif // disp >1											
									endif // disp > 0
									
								// store measurements
									sechalf=V_levelX
									APfwhm=sechalf-firsthalf
									//AHP stats
									wavestats /Q/R=(aploc,aploc+ahp_offset ) waveletz
									AHPamp=V_min-threshold
									AHPloc=V_minloc-APloc
									AHPmin=V_min
									alldata[myspikes][0]=iwave
									alldata[myspikes][1]=thisspike
									alldata[myspikes][2]=interval
									alldata[myspikes][3]=aploc
									alldata[myspikes][4]=APamp
									alldata[myspikes][5]=APfwhm
									alldata[myspikes][6]=AHPamp
									alldata[myspikes][7]=AHPloc
									alldata[myspikes][8]=AHPmin
									alldata[myspikes][9]=dAPrisemax
									alldata[myspikes][10]=threshold
									alldata[myspikes][11]=baseline
									event_reltime[myspikes]=tstart+aploc-tstart0
									event_abstime[myspikes]=tstart+aploc
									iprop=2
									do
										tracedata[iwave][iprop]=tracedata[iwave][iprop]+alldata[myspikes][iprop]
										iprop+=1
									while(iprop<nprops)
									thisspike+=1
									myspikes+=1
								else
									print "couldn't locate halfmax downside--halfmax bottom"
								endif // xxx backside of halfmax
							else
								print "couldn't locate halfmax frontside--halfmax top"
							endif  //+++ frontside of halfmax
						else
							print "big delay between threshold and peak", start0, dpeak_time,1000*(dpeak_time-start0)
						endif
					endif			
				else
					print "rejected duplicate spikes ",prevloc,v_maxloc
				endif
				ispike+=2
			while(ispike<Levels0) // loop over spikes in a wave
		endif
		tracedata[iwave][0]=iwave
		tracedata[iwave][1]=nspikes
		tracedata[iwave][11]=baseline
		trace_reltime[iwave]=tstart-tstart0
		trace_abstime[iwave]=tstart
		
		iprop=2
		do	
			if(nspikes>0)
				offset=0
				if(iprop==2)
					offset=-1
				endif
				tracedata[iwave][iprop]/=(nspikes+offset)
				//print myspikes, iprop, tracedata[iwave][iprop]
			endif
			iprop+=1
		while(iprop<nprops)
//		print nspikes, tracedata[iwave][2],tracedata[iwave][3],tracedata[iwave][10],tracedata[iwave][11]
		iwave+=1
		wavelet=stringfromlist(iwave,wavelist)
	while(iwave<nwaves)
	
	// make the graph colorful
	rainbow()
	
	redimension /N=(myspikes,12) alldata
	redimension /N=(myspikes) event_abstime
	redimension /N=(myspikes) event_reltime

	wavelet = removequotes(stringfromlist(0,wavelist))
	string alldataname=wavelet+"_alldata", tracedataname=wavelet+"_tracedata"

	duplicate/O alldata, $alldataname
	duplicate/O tracedata, $tracedataname
	edit/k=1/W=(600,400,1200,800) event_abstime,event_reltime,$alldataname
	ModifyTable format(event_abstime)=8

	edit/k=1/W=(1200,800,1800,1200) trace_abstime,trace_reltime,$tracedataname
	ModifyTable format(trace_abstime)=8
	
end

function EventPropZ(minslope)
	variable minslope // AP threshold at 1V/sec
	print "Using minslope = ",minslope,". For action potentials, this should be 10!"

	variable eoi=1
	string mywavelist=tracenamelist("",";",1)
	string wavelet=stringfromlist(0,mywavelist),wavenote
	variable nwaves=itemsinlist(mywavelist)
	variable iwave=0,ispike=0,prevloc=0
	variable threshold//=$(wavelet)(xcsr(a))
	variable interval,APloc,APamp,APFWHM
	variable AHPamp,AHPFWHM,AHPloc,AHPmin
	variable halfmax0,firsthalf,sechalf
	variable start0,end0,levels0,maxlevels=30
	variable dAPrisemax,thresholdloc
	string dwave,twave,tablelist
	variable tablecount=0
	variable frontrange=1e-3, backrange=2e-3
	variable basestart=0, baseend=0.005,baseline,estart,eend
	variable Ih_offset=0.1,myspikes=0,thisspike=0
	
	iwave=0
	
	wavelet=removequotes(removequotes(stringfromlist(iwave,mywavelist)))
	WAVE waveletZ = $wavelet
	wavenote=note(waveletZ)

//	estart = leftx(waveletZ)
//	eend = rightx(waveletZ)

estart = xcsr(a)
eend = xcsr(b)
	print estart, eend
//	estart=epoch_start(eoi,wavenote)
//	eend=epoch_end(eoi,wavenote)

	//cursor a, $(wavelet), estart+Ih_offset
	//cursor b, $(wavelet),eend
	//makeivcsr()
	showinfo
	cursor a, $wavelet, estart
	cursor b, $wavelet,eend
	//	if(iwave==(nwaves-1))
			maxlevels=500
	//	endif
		make /N=(maxlevels,12)/O alldata
//		WAVE twaveZ = $(twave)
		myspikes=0
		alldata=nan

	do

		wavelet=removequotes(wavelet)
		WAVE waveletZ = $wavelet
		wavestats /Q/R=(basestart,baseend) waveletZ
		baseline=V_avg
		twave="t"+wavelet
		dwave="d"+wavelet
//		WAVE waveletZ = $wavelet
		duplicate/O waveletz, $(dwave)
		differentiate $(dwave)
//		findlevels /R=(estart,eend)/Q waveletZ,minslope //assumes action potentials cross zero
		findlevels /R=(estart,eend)/Q $dwave,minslope //use der threshold only!!! 20140825
		levels0=V_levelsFound
		duplicate/O w_findlevels, levelswave
		duplicate/o levelswave, yaxis
		
		yaxis=0
//		appendtograph yaxis vs levelswave
		print iwave, wavelet, levels0/2
	if(levels0>0)
		
		ispike=0

		prevloc=0
		interval=0
		thisspike=0
		do
			start0=levelswave[ispike]-frontrange
//			print start0,ispike
			end0=levelswave[ispike]+backrange
			wavestats /Q/R=(start0,end0) waveletZ
			if(ispike>0) 
				interval=V_maxloc-prevloc
			endif
		
		if(V_maxloc!=prevloc)
		// reject duplicate spikes!!!	
		
			prevloc=V_maxloc
			APloc=V_maxloc
			APamp=V_max
			wavestats /Q/R=(start0,end0) $(dwave)
			dAPriseMax=V_max
			if((start0>rightx($(dwave)))%|(V_maxloc>rightx($(dwave))))
				print "ran out of data--spike properties of the edge of recording"
			else
			//	cursor a, $(wavelet), start0
			//	cursor b, $(wavelet),v_maxloc
			//	doupdate
			//	findlevel /B=21/Q/R=(start0,V_maxloc) $(dwave), minslope
				findlevel /b=5/Q/R=(start0,V_maxloc) $(dwave), minslope

				if(v_flag==0) 
					threshold=waveletz(V_levelX)
					APamp-=threshold
					halfmax0=threshold+0.5*APamp
					findlevel /Q/R=(start0,APloc) waveletz, halfmax0
			//		cursor a, $(wavelet), start0
			//		cursor b, $(wavelet),APloc
			//		doupdate
			//		print "set range for halfmax upside"
					//find halfmax upside
					if(v_flag==0)
						firsthalf=V_levelX
						findlevel /Q/R=(APloc,end0) waveletz, halfmax0
			//			cursor a, $(wavelet), APloc
			//			cursor b, $(wavelet),end0
			//			doupdate
			//			print "set range for halfmax downside"
						//find halfmax downside
						if(v_flag==0)
							
							sechalf=V_levelX
							APfwhm=sechalf-firsthalf
							//AHP stats
							wavestats /Q/R=(aploc,aploc+0.02) waveletz
							AHPamp=V_min-threshold
							AHPloc=V_minloc-APloc
							AHPmin=V_min
							alldata[myspikes][0]=iwave
							alldata[myspikes][1]=thisspike
							alldata[myspikes][2]=interval
							alldata[myspikes][3]=aploc
							alldata[myspikes][4]=APamp
							alldata[myspikes][5]=APfwhm
							alldata[myspikes][6]=AHPamp
							alldata[myspikes][7]=AHPloc
							alldata[myspikes][8]=AHPmin
							alldata[myspikes][9]=dAPrisemax
							alldata[myspikes][10]=threshold
							alldata[myspikes][11]=baseline
							thisspike+=1
							myspikes+=1
						else
							print "couldn't locate halfmax downside--halfmax bottom"
						endif // backside of halfmax
					else
						print "couldn't locate halfmax frontside--halfmax top"
					endif  // frontside of halfmax
				else
					print "over the edge too"
				endif
			endif
//			print wavelet,iwave,ispike,interval,aploc,APamp,APfwhm,AHPamp,AHPloc
			
			else
				print "rejected duplicate spikes ",prevloc,v_maxloc
			endif
			
			ispike+=2
		while(ispike<Levels0)
	endif
		iwave+=1
		wavelet=stringfromlist(iwave,mywavelist)
	while(iwave<nwaves)

end

function APpropZ()
	variable minslope=1 // AP threshold at 1V/sec
	variable smoothing=10
	print "Using minslope = ",minslope,". For GNRH action potentials, this should be 1!"

	variable eoi=1
	string wavelist=tracenamelist("",";",1)
	string wavelet=stringfromlist(0,wavelist),wavenote
	variable nwaves=itemsinlist(wavelist)
	variable iwave=0,ispike=0,prevloc=0
	variable threshold=0//=$(wavelet)(xcsr(a))
	variable threshold_time=0,dpeak_time=0
	variable interval,APloc,APamp,APFWHM
	variable AHPamp,AHPFWHM,AHPloc,AHPmin
	variable halfmax0,firsthalf,sechalf
	variable start0,end0,levels0,maxlevels=6000
	variable dAPrisemax,thresholdloc
	string dwave,twave,tablelist
	variable tablecount=0
	variable frontrange=3e-3, backrange=3e-3 // assumes units are seconds!!!
	variable basestart=0, baseend=0.005,baseline,estart,eend
	variable Ih_offset=0.1,myspikes=0,thisspike=0
	
	iwave=0
	
	wavelet=removequotes(removequotes(stringfromlist(iwave,wavelist)))
	WAVE waveletZ = $wavelet
	wavenote=note(waveletZ)

	estart = leftx(waveletZ)
	eend = rightx(waveletZ)
	
//	estart=epoch_start(eoi,wavenote)
//	eend=epoch_end(eoi,wavenote)

	//cursor a, $(wavelet), estart+Ih_offset
	//cursor b, $(wavelet),eend
	//makeivcsr()
	showinfo
	cursor a, $wavelet, estart
	cursor b, $wavelet,eend
	//	if(iwave==(nwaves-1))
	//		maxlevels=500
	//	endif
		make /N=(maxlevels,12)/O alldata
//		WAVE twaveZ = $(twave)
		myspikes=0
		alldata=nan

	do //loop over each wave in graph

		wavelet=removequotes(wavelet)
		WAVE waveletZ = $wavelet
		wavestats /Q/R=(basestart,baseend) waveletZ
		baseline=V_avg
		twave="t"+wavelet
		dwave="d"+wavelet
//		WAVE waveletZ = $wavelet
		duplicate/O waveletz, $(dwave)
		differentiate $(dwave)
		findlevels /R=(estart,eend)/Q waveletZ,0 //assumes action potentials cross zero!
		levels0=V_levelsFound
		duplicate/O w_findlevels, levelswave
		duplicate/o levelswave, yaxis
		
		yaxis=0
//		appendtograph yaxis vs levelswave
		print iwave, wavelet, levels0/2
	if(levels0>0)
		
		ispike=0

		prevloc=0
		interval=0
		thisspike=0
		do
			start0=levelswave[ispike]-frontrange
//			print start0,ispike
			end0=levelswave[ispike]+backrange
			wavestats /Q/R=(start0,end0) waveletZ
			if(ispike>0) 
				interval=V_maxloc-prevloc
			endif
		
		if(V_maxloc!=prevloc)
		// reject duplicate spikes!!!	
		
			prevloc=V_maxloc
			APloc=V_maxloc
			APamp=V_max
			wavestats /Q/R=(start0,end0) $(dwave)
			dpeak_time=V_maxloc
			dAPriseMax=V_max
			if((start0>rightx($(dwave)))%|(dpeak_time>rightx($(dwave))))
				print "ran out of data--spike properties of the edge of recording"
			else
				findlevel /b=(smoothing)/Q/R=(start0,dpeak_time) $(dwave), minslope
				threshold_time=V_LevelX
				if(v_flag==0) //if the threshold is between start0 and the peak of the derivative
					threshold=waveletz(V_levelX)
					APamp-=threshold
					halfmax0=threshold+0.5*APamp
					findlevel /Q/R=(start0,APloc) waveletz, halfmax0
					//+++ find halfmax upside
					if(v_flag==0)
						firsthalf=V_levelX
						findlevel /Q/R=(APloc,end0) waveletz, halfmax0
						//xxx find halfmax downside
						if(v_flag==0)
							
							sechalf=V_levelX
							APfwhm=sechalf-firsthalf
							//AHP stats
							wavestats /Q/R=(aploc,aploc+0.02) waveletz
							AHPamp=V_min-threshold
							AHPloc=V_minloc-APloc
							AHPmin=V_min
							alldata[myspikes][0]=iwave
							alldata[myspikes][1]=thisspike
							alldata[myspikes][2]=interval
							alldata[myspikes][3]=aploc
							alldata[myspikes][4]=APamp
							alldata[myspikes][5]=APfwhm
							alldata[myspikes][6]=AHPamp
							alldata[myspikes][7]=AHPloc
							alldata[myspikes][8]=AHPmin
							alldata[myspikes][9]=dAPrisemax
							alldata[myspikes][10]=threshold
							alldata[myspikes][11]=baseline
							thisspike+=1
							myspikes+=1
						else
							print "couldn't locate halfmax downside--halfmax bottom"
						endif // xxx backside of halfmax
					else
						print "couldn't locate halfmax frontside--halfmax top"
					endif  //+++ frontside of halfmax
				else
					print "big delay between threshold and peak", start0, dpeak_time,1000*(dpeak_time-start0)
				endif
			endif
//			print wavelet,iwave,ispike,interval,aploc,APamp,APfwhm,AHPamp,AHPloc
			
			else
				print "rejected duplicate spikes ",prevloc,v_maxloc
			endif
			
			ispike+=2
		while(ispike<Levels0)
	endif
		iwave+=1
		wavelet=stringfromlist(iwave,wavelist)
	while(iwave<nwaves)

end
function EventPropZ2(thresh,smth,offset)
	variable thresh, smth , offset
//	print "Using minslope = ",minslope,". For action potentials, this should be 10!",thresh

	variable eoi=1
	string wavelist=tracenamelist("",";",1)
	string wavelet=stringfromlist(0,wavelist),wavenote
	variable nwaves=itemsinlist(wavelist)
	variable iwave=0,ispike=0,prevloc=0
	variable threshold//=$(wavelet)(xcsr(a))
	variable interval,APloc,APamp,APFWHM
	variable AHPamp,AHPFWHM,AHPloc,AHPmin
	variable halfmax0,firsthalf,sechalf
	variable start0,end0,levels0,maxlevels=30
	variable dAPrisemax,thresholdloc
	string dwave,twave,tablelist
	variable tablecount=0
	variable frontrange=1e-3, backrange=2e-3
	variable basestart=0, baseend=0.005,baseline,estart,eend
	variable Ih_offset=0.1,myspikes=0,thisspike=0,ievent=0,delta_level=0, ilevel=0,delta=0
	variable thistime=0
	
	iwave=0
	
	wavelet=removequotes(removequotes(stringfromlist(iwave,wavelist)))
	WAVE waveletZ = $wavelet
	wavenote=note(waveletZ)

//	estart = leftx(waveletZ)
//	eend = rightx(waveletZ)

estart = xcsr(a)
eend = xcsr(b)
	print estart, eend
//	estart=epoch_start(eoi,wavenote)
//	eend=epoch_end(eoi,wavenote)

	//cursor a, $(wavelet), estart+Ih_offset
	//cursor b, $(wavelet),eend
	//makeivcsr()
	showinfo
	cursor a, $wavelet, estart
	cursor b, $wavelet,eend
	//	if(iwave==(nwaves-1))
			maxlevels=500
	//	endif
		make /N=(maxlevels,12)/O alldata
//		WAVE twaveZ = $(twave)
		myspikes=0
		alldata=nan

		wavelet=removequotes(wavelet)
		WAVE waveletZ = $wavelet
	
		wavestats /Q/R=(estart,eend) waveletZ
		baseline=V_avg
		twave="t"+wavelet
		dwave="d"+wavelet
//		WAVE waveletZ = $wavelet
		duplicate/O/r=(estart,eend) waveletz, mynewwave
		smooth smth, mynewwave
		differentiate mynewwave
//		display mynewwave
		findlevels /edge=1/R=(estart,eend)/Q mynewwave,thresh //assumes action potentials cross zero
		levels0=V_levelsFound
		duplicate/o w_findlevels, mylevels
		
		ievent=1
		ilevel=1
		do
			delta_level=0
			thistime=mylevels[ilevel]
			do
				delta=mylevels[ilevel]-mylevels[ilevel-1]
				delta_level+=delta
				ilevel+=1
			while((delta_level<offset)||(ilevel<levels0))
			
			print thistime,mylevels[ilevel], delta_level
			ievent+=1
		while(ilevel<levels0)
print levels0
return ievent
end
