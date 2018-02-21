#pragma rtGlobals=3		// Use modern global access method and strict wave access.
	
macro JP_Cluster ()
	buildClusterPanelLUL()
endmacro

function buildClusterPanelLUL()
	// general variable/dimenson setting
	string panelName = "cluster"
	
	variable /G xPos = 20
	variable /G yPos = 40
	variable buttonWidth = 100, buttonHeight = 20
	variable listBoxWidth = 150, listBoxHeight = 150
	
	// creates the panel and sets color
	NewPanel /K=1/W=(50, 50, 1125, 750)/N=$panelName
	modifypanel cbRGB=(50000,50000,50000)

	// makes the display area 
	// 20170116 right was 985, left was 225
	Variable left = 250, top = 35, right = 1045, bottom = 674
	Display /W=(left, top, right, bottom) /HOST=cluster
	RenameWindow #, clusterDisplay
	SetActiveSubwindow ##
	
	// controls for cluster
	variable /G updnEnabled2 = 0
	variable /G mscoreEnabled2 = 0
	variable /G updnPresent2 = 0
	variable /G mscorePresent2 = 0
	variable/G zeroterminate2 = 0
	
//	20170219 added listbox to allow choosing a wave for cluster
	string /G man_wave_name
	SetVariable PopupWaveSelectorSV3,pos={xPos,yPos + 15},size={200,15},title="Select a wave:"
	MakeSetVarIntoWSPopupButton("cluster", "PopupWaveSelectorSV3", "testNotificationFunction2", "root:man_wave_name")
	
	CheckBox mscoreEnabledBox pos={xpos, yPos + 35}, proc=mscoreEnabledBoxProc2, title="Show MScore", disable=(0)
	CheckBox updnEnabledBox pos={xpos + buttonwidth, yPos + 35}, proc=updnEnabledBoxProc2, title="Show Up/Down", disable=(0)
	checkbox cbZeroTerminate pos={xpos, yPos + 55}, proc=cbZeroTerminateProc, title="Zero terminate", disable=(0), variable = ZeroTerminate2
	
	variable /G g_npntsUP2 = 2
	variable /G g_npntsDN2 = 2
	variable /G g_TscoreUP2 = 2.0
	variable /G g_TscoreDN2 = 2.0
	variable /G g_minPeak2 = 0.0
	variable /G g_halflife2 = 0.0
	variable /G g_outlierTscore2 = 4.0
	variable /G g_minNadir2 = -1
	
	SetVariable numPointsPeak pos={xPos, yPos + 75}, size={200,20}, value=g_npntsUP2, title="# Points for Peak", disable=(0), limits={0,inf,1}
	SetVariable numPointsNadir pos={xPos, yPos + 95}, size={200,20}, value=g_npntsDN2, title="# Points for Nadir", disable=(0), limits={0,inf,1}
	SetVariable tscoreIncrease pos={xPos, yPos + 115}, size={200,20}, value=g_TscoreUP2, title="T-Score for Increase", disable=(0), limits={0,inf,0.1}
	SetVariable tscoreDecrease pos={xPos, yPos + 135}, size={200,20}, value=g_TscoreDN2, title="T-Score for Decrease", disable=(0), limits={0,inf,0.1}
	SetVariable minPeakSize pos={xPos, yPos + 155}, size={200,20}, value=g_minPeak2, title="Minimum Peak Size", disable=(0), limits={0,inf,0.1}
	SetVariable minNadir pos={xPos, yPos+175}, size={200,20}, value=g_minNadir2, title="Minimum Nadir", disable=(0), limits={-1, inf, .1}
	SetVariable halfLife pos={xPos, yPos + 195}, size={200,20}, value=g_HalfLife2, title="Half-Life", disable=(0), limits={0,inf,0.1}
	SetVariable outlierTscore pos={xPos, yPos + 215}, size={200,20}, value=g_outlierTscore2, title="Outlier T-Score", disable=(0), limits={0,inf,0.1}
	
	string udata = ""
	Button saveParamDef pos={xPos, yPos + 235}, size={buttonWidth + 90, 20}, title="Save Parameters as Default", disable=(0), proc=cluster_buStoreParams, userdata=udata
	udata += "target:"
	udata += "cluster#clusterDisplay;"
	udata += "hw:;"
	Button calculate pos={xPos, yPos + 255}, size={buttonWidth, 20}, title="Calculate", disable=(0),proc=jcluster_buCalculate2, userdata=udata
	udata = ""
	Button viewResults pos={xPos, yPos +275}, size={buttonWidth - 5,20}, title="View Results", disable=(0),proc = cluster_buViewResults, userdata=udata
	Button printResults pos={xPos + buttonWidth + 5, yPos + 275}, size={buttonWidth - 8,20}, title= "Print Results", disable=(0), proc = cluster_buPrintResults, userdata=udata
	
	valdisplay nPeaks pos = {xPos, yPos + 300}, size={100, 20}, title="n Peaks", disable=(0)
	valdisplay nNadirs, pos={xPos, yPos + 317}, size={100,20}, title="n Nadirs", disable=(0)
	
	Button storeResults, pos={xPos,yPos + 335}, size={buttonWidth, buttonHeight}, title="Store Results", disable=(0), proc=cluster_buStoreResults, userdata=udata
	Button recallResults, pos={xPos + buttonWidth + 5,yPos + 335}, size={buttonWidth - 8, buttonHeight}, title="Recall Results", disable=(0), proc=cluster_buRecallResults, userdata=udata
	
	variable /G gRadioVal3 = 1, gSQRTOvalue2 = 0.01, gFixedValue2 = 0.1
	CheckBox cbGlobalSD, pos={xPos, yPos + 360}, size={78,15}, title="Global: SD", value=1, mode=1, disable=(0),proc=clustercheckProc
	CheckBox cbGlobalSE, pos={xPos + 105, yPos + 360}, size={78,15}, title="SE", value=0,mode=1, disable=(0),proc=clustercheckProc
	CheckBox cbLocalSD, pos={xPos, yPos + 380}, size={78,15}, title="Local: SD", value=0, mode=1, disable=(0),proc=clustercheckProc
	CheckBox cbLocalSE, pos={xPos + 105, yPos + 380}, size={78,15}, title="SE", value=0, mode=1, disable=(0),proc=clustercheckProc
	CheckBox cbSQRT, pos={xPos, yPos + 400}, size={78,15}, title="SQRT", value=0, mode=1, disable=(0),proc=clustercheckProc
	SetVariable svSQRTOvalue, pos={xPos + 105, yPos + 400}, size={90,20},title="Zero:", value=gSQRTOvalue2, limits={0,inf,0.1}, disable=(0)
	CheckBox cbFixed,pos={xPos, yPos + 420},size={78,15},title="Fixed:",value=0,mode=1, disable=(0),proc=clustercheckProc
	SetVariable svFixedValue, pos={xPos + 105, yPos + 420}, size={90,20}, title="Value:", value=gFixedValue2,limits={0,inf,0.1}, disable=(0)
	CheckBox cbErrWave,pos={xPos, yPos + 440}, size={78,15},title="Wave:", value=0, mode=1, disable=(0),proc=clustercheckProc
	
	String quote = "\""
	string errwl=""
	errwl = quote + "NONE;" + wavelist("*",";", "") + quote // list of all current waves in local igor data folder
	errwl =  quote + "NONE;" + quote
	PopupMenu puErrWaveName pos={xPos, yPos + 460}, size={100, 20}, title="Wave:", mode=2, disable=(0),userdata=udata
	PopupMenu puErrWaveName value = #errwl
	udata = ""
	udata = "puErrWaveName"
	Button buUpdateErrWLPU, pos={xPos + buttonWidth + 5,yPos + 460},size={buttonWidth - 10, buttonHeight}, title="Update Wave", disable=(0),proc=cluster_buUpdateWL, userdata=udata

	// MISC
	udata = "target:cluster#clusterDisplay;"
	Button resetZoom pos={xPos, yPos + 600}, size={buttonWidth, buttonHeight}, title="Reset zoom", proc=resetZoomProc2, userdata = udata
	
	// placing this here to make sure is defined for man wave
	string /G histoAxis = "histo"
	string /G upsAxis = "lower1"
	string /G downAxis = "lower2"
end

// function that handles the calc button/actually does the cluster analysis stuff
function jcluster_buCalculate2(s) : ButtonControl
	Struct WMButtonAction &s
	
	// 20170111 added /z to prevent debugger // and moved into event code if statement (no ref needed if no click)
	if (s.eventcode == 2)
		NVAR/Z gRadioVal3 = root:gRadioVal3
		NVAR/Z gSQRTOvalue2 = root:gSQRTOvalue2
		NVAR/Z gFixedValue2 = root:gFixedValue2
		NVAR/Z gZeroTerminate2 = root:ZeroTerminate2
		
		string mscorewn = "", wn_ups="", wn_dns="",	 thisAxis = "", thiswn = ""

		//removes old graphs
		string target = stringbykey("target", s.userdata)
		string cluster_waves
		variable item = 0
		variable nitems
		string rwn
		
		setactivesubwindow $target
		setdatafolder root:
		cluster_waves = WaveList("Mscore*", ";", "")
		cluster_waves += WaveList("ups*", ";", "")
		cluster_waves += WaveList("downs*", ";", "")
		nitems = itemsinlist(cluster_waves)
		if (nitems > 0)
			do
				rwn = stringfromlist(item, cluster_waves)
				WAVE rw = $rwn
				removefromgraph /Z $rwn
				item += 1
			while (item < nitems)
		endif
		
		string wn
		SVAR man_wave_name = root:man_wave_name
		wn = man_wave_name
		
		variable nPeaks, nNadir, tScoreUp, tScoreDN, minPeak, minNadir, halfLife, outScore 
		
		controlinfo numPointsPeak
		nPeaks = v_value
		controlinfo numPointsNadir
		nNadir = v_value
		controlinfo tscoreIncrease
		tScoreUp = v_value
		controlinfo tscoreDecrease
		tScoreDn = v_value
		controlinfo minPeakSize
		minPeak = v_value
		controlinfo minNadir
		minNadir = v_value
		
		outScore = 4
		
		string wn_results = ""
		
		// evaluate error handling; need errorType and errorValue
		string errorType = ""
		variable errorValue = 0
		switch(gRadioVal3)
			case 1:
				//Global SD
				errorType = "Global SD"
				break
			case 2:
				//Global SE
				errorType = "Global SE"
				break
			case 3:
				//local SD
				errorType = "Local SD"
				break				
			case 4:
				//local se
				errorType = "Local SE"
				break
			case 5:
				//sqrt
				errorType = "SQRT"
				errorValue = gSQRTOValue2
				break
			case 6:
				//Global SD
				errorType = "Fixed"
				errorValue = gFixedValue2
				break
			case 7:
				// user provided error wave // \\ // not implemented yet
				errorType = "Error Wave"
				print "in JP cluster: need code to move selected wave to error wave!"
				abort
				break
			default:
				print "switch ClusterMain, unaccounted for errortype code: ", gRadioVal3
				errortype = ""
				errorvalue = 1e-6
		endswitch
		
		//20170111 if error value is lost, warn the user!
		if( numtype( errorvalue ) != 0 )
			print "jp cluster handler: errorvalue = nan: ", errorvalue
			errorvalue = 1e-6
			print " jp cluster handler: reset to:", errorvalue
		endif
		
		string outlist = ""
		outlist = ClusterMain(wn, nPeaks, nNadir, tScoreUp, tScoreDn, minPeak, halfLife, outScore, errorType, errorValue, zeroTerminate = gZeroTerminate2)
		
		wn_results = stringfromlist( 0, outlist )
		wn_ups = stringfromlist( 1, outlist )
		wn_dns = stringfromlist( 2, outlist )

		WAVE w_results = $wn_results
		WAVE w_ups = $wn_ups
		WAVE w_dns = $wn_dns
		
		target = stringbykey("target", s.userdata)
		setactivesubwindow $target
		
		string oldtraces=tracenamelist("",";",1)
		
		// graphs the stuff
		NVAR binBeginVSV, binEndVSV
		NVAR updnEnabled2, mscoreEnabled2, updnPresent2, mscorePresent2
		
		if(strsearch( oldtraces, wn_results, 0) < 0)
			AppendToGraph/R w_results //20170110 this labels the pulses from cluster analysis
			string pulseAxis = "Right"
			ModifyGraph mode($wn_results)=5,rgb($wn_results)=(65535,65535,0)
			ModifyGraph hbFill($wn_results)=2
		// ** 20170109 SET THIS TO HALF THE BINSIZE
			ModifyGraph offset($wn_results)={0,0} // using bar graphs, no realignment necessary
			ModifyGraph axRGB($pulseAxis)=(65535,65535,65535),tlblRGB($pulseAxis)=(65535,65535,65535);DelayUpdate
			ModifyGraph alblRGB($pulseAxis)=(0,65535,0)
			ModifyGraph axisEnab($pulseAxis) = {0, 1}
		endif
		string upAxis = "lower1"
		if(strsearch( oldtraces, wn_ups, 1) < 0)
			if (updnEnabled2)
				AppendToGraph/R=$upAxis w_ups
				modifygraph rgb($wn_ups)=(0,65535,0), mode($wn_ups)=5, hbfill($wn_ups)=2 
				Label $upAxis "\\K(0,0,0) <UP"
				ModifyGraph axRGB($upAxis)=(65535,65535,65535),tlblRGB($upAxis)=(65535,65535,65535)
				ModifyGraph alblRGB($upAxis)=(65535,65535,65535)			
				ModifyGraph freePos($upAxis)=20
				updnPresent2 = 1
			endif
		endif
		string dnAxis = "lower2"
		if(strsearch( oldtraces, wn_dns, 1) < 0)
			if (updnEnabled2)
				AppendToGraph/R=$dnAxis w_dns
				modifygraph rgb($wn_dns)=(65535,0,0), mode($wn_dns)=5, hbfill($wn_dns)=2 					
				Label $dnAxis "\\K(0,0,0) DN>"	
				ModifyGraph axRGB($dnAxis)=(65535,65535,65535),tlblRGB($dnAxis)=(65535,65535,65535)
				ModifyGraph alblRGB($dnAxis)=(65535,65535,65535)				
				ModifyGraph freePos($dnAxis)=20
			endif
		endif
		mscorewn = "Mscore_ups_" + wn
		thiswn = ""
		thisAxis = ""	
		thisAxis = "Mscore"
		if(strsearch( oldtraces, mscorewn, 1) < 0)
			thiswn = mscorewn
			WAVE thisW = $thiswn
			if (mscoreEnabled2)
				AppendToGraph/R=$thisAxis thisw  // thisw contains the reference to Mscore
				setaxis $thisaxis, -tscoredn, tscoreup
				modifygraph rgb($thiswn)=(0,0,65535), mode($thiswn)=5, hbfill($thiswn)=2
				ModifyGraph zero($thisAxis)=1
				ModifyGraph freePos($thisAxis)=0
				Label $thisAxis "Mscore"
				ModifyGraph lblPos($thisAxis)=80
				Label $thisAxis "\\K(0,0,0) Mscore"	
				ModifyGraph freePos($thisAxis)=0	
				mscorePresent2 = 1
			endif
		endif
		
		oldtraces = tracenamelist("",";",1)
		string firsttrace = stringfromlist(0,oldtraces)
		if(!stringmatch( firsttrace, wn_results))
			reordertraces $firsttrace, {$wn_results}
		endif
		
		if (mscoreEnabled2)
			string /G mscoreAxis = thisAxis
		endif
		if (updnEnabled2)
			string /G downAxis = dnAxis
			string /G upsAxis = upAxis
		endif
		variable /G modifyHisto = 1
		cluster_resizeWindows()
		modifyHisto = 0	
		
		cluster_resizeWindows()
	endif
end

function mscoreEnabledBoxProc2 (ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	
	NVAR mscoreEnabled2
	mscoreEnabled2 = checked
end

function updnEnabledBoxProc2 (ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	
	NVAR updnEnabled2
	updnEnabled2 = checked
end

// check proc for radio buttons in cluster
function clustercheckProc(name, value)
	String name
	Variable value
	
	NVAR gRadioVal3 = root:gRadioVal3
	
	strswitch (name)
		case "cbGlobalSD":
			gRadioVal3= 1
			break
		case "cbGlobalSE":
			gRadioVal3= 2
			break
		case "cbLocalSD":
			gRadioVal3= 3
			break
		case "cbLocalSE":
			gRadioVal3= 4
			break
		case "cbSQRT":
			gRadioVal3= 5
			break			
		case "cbFixed":
			gRadioVal3= 6
			break
		case "cbErrWave":
			gRadioVal3= 7
			break
	endswitch
	CheckBox cbGlobalSD,value= gRadioVal3==1
	CheckBox cbGlobalSE,value= gRadioVal3==2
	CheckBox cbLocalSD,value= gRadioVal3==3
	CheckBox cbLocalSE,value= gRadioVal3==4
	CheckBox cbSQRT,value= gRadioVal3==5
	CheckBox cbFixed,value= gRadioVal3==6
	CheckBox cbErrWave,value= gRadioVal3==7

end

Function testNotificationFunction2(event, wavepath, windowName, ctrlName)
	Variable event
	String wavepath
	String windowName
	String ctrlName
	
	// doing this to prevent errors when selecting man wave after already having done one
	NVAR mscoreEnabled2, mscorePresent2, updnEnabled2, updnPresent2
	variable prev_mscoreEnabled = mscoreEnabled2
	variable prev_updnEnabled = updnEnabled2
	variable prev_mscorePresent = mscorePresent2
	variable prev_updnPresent = updnPresent2
	mscoreEnabled2 = 0
	mscorePresent2 = 0
	updnEnabled2 = 0
	updnPresent2 = 0
	
	print "Selected wave:",wavepath, " using control", ctrlName
	
	// empty graph
	string target = "cluster#clusterDisplay"
	string wl = "", rwn2 = ""
	wl = tracenamelist(target,  ";" , 1 )
	variable item2=0, nitems2=itemsinlist(wl)

	if (nitems2>0)
		do
			rwn2 = stringfromlist( item2, wl )
			WAVE rw2 = $rwn2
			removefromgraph /W=$target $rwn2 
			item2+=1
		while(item2<nitems2)
	endif
	
	// graph the wave given by user
	variable /G modifyHisto = 1
	SVAR histoAxis
	NVAR binBeginVSV, binEndVSV, retainSettingsVSV
	// parse out the path stuff from the wavepath (root:, etc.)
	variable c_index = strsearch(wavepath, ":", Inf, 1)
	if (c_index != -1)	
		wavepath = wavepath[c_index + 1, Inf]
	endif
	// remove start and end quote if there are any
	wavepath = replacestring("'", wavepath, "")
	WAVE wn_wave = $wavepath
		
	appendtograph /W=$target /L=$histoAxis wn_wave
	ModifyGraph /W=$target freePos($histoAxis)=0
	ModifyGraph /W=$target lsize($wavepath) = 1
	ModifyGraph /W=$target rgb($wavepath) = (0, 0, 0)
	ModifyGraph /W=$target mode($wavepath)=5,hbFill($wavepath)=2
	modifyHisto = 0
	string histoLabel2 = ""
	histoLabel2 += "Events per "
	histoLabel2 += num2str(deltax(wn_wave))
	histoLabel2 += " s"
	Label /W=$target histo histoLabel2
	ModifyGraph /W=$target lblPosMode(histo)=2
	
	mscoreEnabled2 = prev_mscoreEnabled
	mscorePresent2 = prev_mscorePresent
	updnEnabled2 = prev_updnEnabled
	updnPresent2 = prev_updnPresent
end

function cluster_resizeWindows()
	variable upBeginVSV = .06
	variable upEndVSV = .1
	variable dnBeginVSV = 0
	variable dnEndVSV = .04
	variable mscoreBeginVSV = .8
	variable mscoreEndVSV = 1
	variable binBeginVSV = 0
	variable binEndVSV = 1
	NVAR modifyHisto, mscoreEnabled2, mscorePresent2, updnEnabled2, updnPresent2
	SVAR mscoreAxis, upsAxis, downAxis, histoAxis
	string target = "cluster#clusterDisplay"
	
	if (mscoreEnabled2 && mscorePresent2)
		ModifyGraph /W=$target axisEnab($mscoreAxis) = {mscoreBeginVSV, mscoreEndVSV}
		binEndVSV = .75
	endif
	if (updnEnabled2 && updnPresent2)
		ModifyGraph /W=$target axisEnab($upsAxis) = {upBeginVSV, upEndVSV}
		ModifyGraph /W=$target axisEnab($downAxis) = {dnBeginVSV, dnEndVSV}
		binBeginVSV = .15
	endif
	
	if (modifyHisto)
		ModifyGraph /W=$target axisEnab($histoAxis) = {binBeginVSV, binEndVSV}
	endif
end

function resetZoomProc2(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventcode == 2)
		SVAR histoAxis
		string target = stringbykey("target", B_Struct.userdata)
		setactivesubwindow $target
		
		SetAxis /A
	endif
end