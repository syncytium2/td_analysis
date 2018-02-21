#pragma rtGlobals=3		// Use modern global access method and strict wave access.
	
structure panelInfo
	string panelName
endstructure

macro JPsmartConcPanel ()
	buildPanel()
endmacro

function buildPanel()
	// general variable/dimenson setting
	STRUCT panelInfo pinfo
	pinfo.panelName = "smartConc"
	
	variable /G xPos = 20
	variable /G yPos = 40
	variable buttonWidth = 100, buttonHeight = 20
	variable listBoxWidth = 150, listBoxHeight = 150
	
	variable /G before = .001, after = .001
	
	// creates the panel and sets color
	NewPanel /K=1/W=(50, 50, 1250, 750)/N=$pinfo.panelName
	modifypanel cbRGB=(50000,50000,50000)
	
	// 20170116 size was 990
	TabControl tabs, pos={5,5}, size={1180,680}, tablabel(0)="Smart Concatenate", proc=tabsproc
	TabControl tabs, tablabel(1)="Vary Burst Window"
	TabControl tabs, tablabel(2)="Cluster"
	TabControl tabs, tablabel(3)="View Settings"
	TabControl tabs, tablabel(4)="Output"
	// 20170907 added to track what graph should be defaulted to
	variable /g SCTABS = 1
	
	// makes the update button
	string udata = ""
	udata += "textwave:"
	udata += "ptbDBTextWave;"
	udata += "listwave:"
	udata += "ptbDBListWave;"
	udata += "selwave:"
	udata += "ptbDBSelWave;"
	Button updateButton, pos={xPos,yPos}, size={buttonWidth, buttonHeight}, title="Update", proc=updatePress, userdata = udata
	
	// makes a temp button to select all waves in the list box
	udata = ""
	udata += "selwave:"
	udata += "ptbDBSelWave;"
	Button selectAllButton, pos={xPos, yPos + 195}, size={buttonWidth, buttonHeight}, title="Select All", proc=selectAllPress, userdata = udata
	
	// makes the listbox and listbox related things
	Make /T /O /N=(0) ptbDBTextWave
	Make /T /O /N=(0) ptbDBListWave
	Make /B /O /N=(0) ptbDBSelWave = 0
	ListBox ptbDisplayBox, mode=4, proc=ptbDisplayBoxProc, listwave=ptbDBListWave, selwave=ptbDBSelWave, pos={xPos, yPos+ 35}, size={listBoxWidth,listBoxHeight}
	
	// makes the setvars for before and after
	SetVariable beforeVar pos={xPos, yPos + 225}, size={120,20}, proc=beforeSetVarProc, value=before, title="Before (sec):", limits={.001,inf,.001}
	SetVariable afterVar pos={xPos, yPos + 250}, size={120,20}, proc=afterSetVarProc, value=after, title="After (sec):", limits={.001,inf,.001}
	
	variable /G gapThresholdV = .0001
	SetVariable gapThreshold pos={xPos, yPos + 300}, size={140, 20}, value=gapThresholdV, title="Gap size (sec):", limits={.0001, inf, .0001}
	
	// makes the smart conc button
	udata = ""
	udata += "target:"
	udata += "smartConc0#smartConcDisplay;"
	udata += "textwave:"
	udata += "ptbDBTextWave;"
	udata += "listwave:"
	udata += "ptbDBListWave;"
	udata += "selwave:"
	udata += "ptbDBSelWave;"
	Button smartConcButton, pos={xPos, yPos + 325}, size={buttonWidth, buttonHeight}, title="Smart Conc", proc=smartConcPress, userdata = udata
	
	// 20170913
	// makes the shuffle button 
	udata = ""
	udata += "textwave:"
	udata += "ptbDBTextWave;"
	udata += "listwave:"
	udata += "ptbDBListWave;"
	udata += "selwave:"
	udata += "ptbDBSelWave;"
	Button shuffleButton, pos={xPos, yPos + 350}, size={buttonWidth, buttonHeight}, title="Shuffle", proc=shufflePress, userdata = udata

	// makes the setvar for binning
	// 20170116 limits changed to 99 to avoid name too long error on 3 digit numbers
	variable /G binsize = 60
	SetVariable binSizeVar pos={xpos + 65, yPos + 275}, size={55,20}, proc=binSizeVarProc, value=binsize, title=" ", limits={.1,inf, .001}
	
	// makes the checkbox for binning
	variable /G binenabled = 0
	CheckBox binEnabledBox pos={xpos, ypos + 275}, proc=binEnabledBoxProc, title="Bin (sec): "
	
	// makes the display area 
	// 20170116 right was 985, left was 225
	Variable left = 285, top = 35, right = 1045, bottom = 674
	Display /W=(left, top, right, bottom) /HOST=smartConc0
	RenameWindow #, smartConcDisplay
	SetActiveSubwindow ##
	
	// controls for VBW
	udata = ""
	udata += "target:"
	udata += "smartConc0#smartConcDisplay;"
	udata += "sct:"
	
	// 20170111 changed defaults
	variable /G vbwmin = 1, vbwmax = 60, vbwint = 1
	variable /G vbwEnabled = 0
	
	SetVariable vbwmin pos={xPos, yPos + 200}, size={160,20}, proc=vbwminSetVarProc, value=vbwmin, title="Burst window start (sec):", disable=(1)
	SetVariable vbwmax pos={xPos, yPos + 225}, size={160,20}, proc=vbwmaxSetVarProc, value=vbwmax, title="Burst window max (sec):", disable=(1)
	SetVariable vbwint pos={xPos, yPos + 250}, size={160,20}, proc=vbwintSetVarProc, value=vbwint, title="Increment (sec):", disable=(1)
	Button neoVBWButton pos={xPos, yPos + 300}, size={120,20}, proc=neoVBWButtonProc, title="Make VBW Graph", disable=(1), userdata = udata
	variable /G neoVBWButtonRVal = 1
	CheckBox cbNR, pos={xPos, yPos + 275}, size = {78,15}, title="Use one region", value = 1, mode = 1, disable=(1), proc=vbwCheckProc
	CheckBox cbWR, pos={xPos + 110, yPos + 275}, size = {78,15}, title="Use region table info", value = 0, mode = 1, disable=(1), proc=vbwCheckProc
	Button vbwButton pos={xPos, yPos + 275}, size={120,20}, proc=vbwButtonProc, title="Make VBW Graph",  disable=(1), userdata = udata
// 20170111 new vbw button for regions
	variable /G regionVBWEnabled = 0
	Button vbwButton2 pos={xPos, yPos + 300}, size={140,20}, proc=vbwButtonProc2, title="Regions VBW Graph",  disable=(1), userdata = udata
	
	string /G nameswn = "names"
	string  /G startswn = "starts"
	string /G endswn = "ends"

	make/T/O/N=(4) $nameswn
	make/O/N=(4) $startswn
	make/O/N=(4) $endswn	
// 20170219 now starts off unhidden, adjusts the column width, then hides the table so as to prevent part of the table from showing
//          when macro is first opened
	edit /N=vbwRegionTable /HIDE=(0) /K=1 /HOST=smartConc0 /W=(20, yPos + 330, 275, yPos + 600) $nameswn, $startswn, $endswn
	ModifyTable width(Point)=30
	ModifyTable width($nameswn)=75
	ModifyTable width($startswn)=60
	ModifyTable width($endswn)=60
	SetWindow smartConc0#vbwRegionTable hide=(1)
	SetActiveSubWindow smartConc0#smartConcDisplay
	udata = ""
	Button makeVbwTablesButton pos={xPos, yPos + 610}, size={120, 20}, proc=makeVbwTablesProc, title="Make VBW tables", disable=(1), userdata = udata
	
	// controls for cluster
	variable /G updnEnabled = 0
	variable /G mscoreEnabled = 0
	variable /G updnPresent = 0
	variable /G mscorePresent = 0
	variable/G zeroterminate = 0
	
//	20170219 added listbox to allow choosing a wave for cluster
	string /G man_wave_name
	SetVariable PopupWaveSelectorSV3,pos={xPos,yPos + 15},size={200,15},title="Select a wave:", disable=(1)
	MakeSetVarIntoWSPopupButton("smartConc0", "PopupWaveSelectorSV3", "testNotificationFunction", "root:man_wave_name")
// hides the little button that the above function makes next to the listbox
	Button PopupWS_Button0, disable=(1)
	
	CheckBox mscoreEnabledBox pos={xpos, yPos + 190}, proc=mscoreEnabledBoxProc, title="Show MScore", disable=(1)
	CheckBox updnEnabledBox pos={xpos + buttonwidth, yPos + 190}, proc=updnEnabledBoxProc, title="Show Up/Down", disable=(1)
	checkbox  cbZeroTerminate pos={xpos, yPos + 210}, proc=cbZeroTerminateProc, title="Zero terminate", disable=(1), variable = ZeroTerminate
	
	variable/G g_npntsUP = 2
	variable/G g_npntsDN = 2
	variable/G g_TscoreUP = 2.0
	variable/G g_TscoreDN = 2.0
	variable/G g_minPeak = 0.0
	variable/G g_halflife = 0.0
	variable/G g_outlierTscore = 4.0
	variable /G g_minNadir = -1
	
	SetVariable numPointsPeak pos={xPos, yPos + 230}, size={200,20}, value=g_npntsUP, title="# Points for Peak", disable=(1), limits={0,inf,1}
	SetVariable numPointsNadir pos={xPos, yPos + 250}, size={200,20}, value=g_npntsDN, title="# Points for Nadir", disable=(1), limits={0,inf,1}
	SetVariable tscoreIncrease pos={xPos, yPos + 270}, size={200,20}, value=g_TscoreUP, title="T-Score for Increase", disable=(1), limits={0,inf,0.1}
	SetVariable tscoreDecrease pos={xPos, yPos + 290}, size={200,20}, value=g_TscoreDN, title="T-Score for Decrease", disable=(1), limits={0,inf,0.1}
	SetVariable minPeakSize pos={xPos, yPos + 310}, size={200,20}, value=g_minPeak, title="Minimum Peak Size", disable=(1), limits={0,inf,0.1}
	SetVariable minNadir pos={xPos, yPos+330}, size={200,20}, value=g_minNadir, title="Minimum Nadir", disable=(1), limits={-1, inf, .1}
	SetVariable halfLife pos={xPos, yPos + 350}, size={200,20}, value=g_HalfLife, title="Half-Life", disable=(1), limits={0,inf,0.1}
	SetVariable outlierTscore pos={xPos, yPos + 370}, size={200,20}, value=g_outlierTscore, title="Outlier T-Score", disable=(1), limits={0,inf,0.1}
	
	udata = ""
	Button saveParamDef pos={xPos, yPos + 390}, size={buttonWidth + 90, 20}, title="Save Parameters as Default", disable=(1), proc=cluster_buStoreParams, userdata=udata
	udata += "target:"
	udata += "smartConc0#smartConcDisplay;"
	udata += "hw:;"
	Button calculate pos={xPos, yPos + 410}, size={buttonWidth, 20}, title="Calculate", disable=(1),proc=jcluster_buCalculate, userdata=udata
	udata = ""
	Button viewResults pos={xPos, yPos +430}, size={buttonWidth - 5,20}, title="View Results", disable=(1),proc = cluster_buViewResults, userdata=udata
	Button printResults pos={xPos + buttonWidth + 5, yPos + 430}, size={buttonWidth - 8,20}, title= "Print Results", disable=(1), proc = cluster_buPrintResults, userdata=udata
	
	valdisplay nPeaks pos = {xPos, yPos + 455}, size={100, 20}, title="n Peaks", disable=(1)
	valdisplay nNadirs, pos={xPos, yPos + 472}, size={100,20}, title="n Nadirs", disable=(1)
	
	Button storeResults, pos={xPos,yPos + 490}, size={buttonWidth, buttonHeight}, title="Store Results", disable=(1), proc=cluster_buStoreResults, userdata=udata
	Button recallResults, pos={xPos + buttonWidth + 5,yPos + 490}, size={buttonWidth - 8, buttonHeight}, title="Recall Results", disable=(1), proc=cluster_buRecallResults, userdata=udata
	
	variable /G gRadioVal2 = 1
	CheckBox cbSC, pos={xPos, yPos - 5}, size = {78,15}, title="SC w/ binning wave", value = 1, mode = 1, disable=(1), proc=checkProc2
	CheckBox cbMW, pos={xPos + 110, yPos - 5}, size = {78,15}, title="Insert own wave", value = 0, mode = 1, disable=(1), proc=checkProc2
	
	variable /G gRadioVal = 1, gSQRTOvalue = 0.01, gFixedValue = 0.1
	CheckBox cbGlobalSD, pos={xPos, yPos + 515}, size={78,15}, title="Global: SD", value=1, mode=1, disable=(1),proc=checkProc
	CheckBox cbGlobalSE, pos={xPos + 105, yPos + 515}, size={78,15}, title="SE", value=0,mode=1, disable=(1),proc=checkProc
	CheckBox cbLocalSD, pos={xPos, yPos + 535}, size={78,15}, title="Local: SD", value=0, mode=1, disable=(1),proc=checkProc
	CheckBox cbLocalSE, pos={xPos + 105, yPos + 535}, size={78,15}, title="SE", value=0, mode=1, disable=(1),proc=checkProc
	CheckBox cbSQRT, pos={xPos, yPos + 555}, size={78,15}, title="SQRT", value=0, mode=1, disable=(1),proc=checkProc
	SetVariable svSQRTOvalue, pos={xPos + 105, yPos + 555}, size={90,20},title="Zero:", value=gSQRTOvalue, limits={0,inf,0.1}, disable=(1)
	CheckBox cbFixed,pos={xPos, yPos + 575},size={78,15},title="Fixed:",value=0,mode=1, disable=(1),proc=checkProc
	SetVariable svFixedValue, pos={xPos + 105, yPos + 575}, size={90,20}, title="Value:", value=gFixedValue,limits={0,inf,0.1}, disable=(1)
	CheckBox cbErrWave,pos={xPos, yPos + 595}, size={78,15},title="Wave:", value=0, mode=1, disable=(1),proc=checkProc
	
	String quote = "\""
	string errwl=""
	errwl = quote + "NONE;" + wavelist("*",";", "") + quote // list of all current waves in local igor data folder
	errwl =  quote + "NONE;" + quote
	PopupMenu puErrWaveName pos={xPos, yPos + 615}, size={100, 20}, title="Wave:", mode=2, disable=(1),userdata=udata
	PopupMenu puErrWaveName value = #errwl
	udata = ""
	udata = "puErrWaveName"
	Button buUpdateErrWLPU, pos={xPos + buttonWidth + 5,yPos + 615},size={buttonWidth - 10, buttonHeight}, title="Update Wave", disable=(1),proc=cluster_buUpdateWL, userdata=udata
	
	// view settings controls
	variable /G smartConcBeginVSV = 0, smartConcEndVSV = 1
	variable /G binBeginVSV = 0, binEndVSV = 1
	variable /G vbwBeginVSV = 0, vbwEndVSV = 1
	variable /G mscoreBeginVSV = 0, mscoreEndVSV = 1
	variable /G upBeginVSV = 0, upEndVSV = 1
	variable /G dnBeginVSV = 0, dnEndVSV = 1
	
	udata = ""
	udata += "target:"
	udata += "smartConc0#smartConcDisplay;"
	
	SetVariable smartConcBeginVS pos={xPos, yPos}, size={160,20}, proc=smartConcVS, value=smartConcBeginVSV, title="Smart conc begin:", disable=(1), limits={0,1, .01}
	SetVariable smartConcEndVS pos={xPos, yPos + 25}, size={160,20}, proc=smartConcVS, value=smartConcEndVSV, title="Smart conc end:", disable=(1), limits={0,1, .01}
	SetVariable binBeginVS pos={xPos, yPos + 50}, size={160,20}, proc=binVS, value=binBeginVSV, title="Bin begin:", disable=(1), limits={0,1, .01} 
	SetVariable binEndVS pos={xPos, yPos + 75}, size={160,20}, proc=binVS, value=binEndVSV, title="Bin end:", disable=(1), limits={0,1, .01} 
	SetVariable vbwBeginVS pos={xPos, yPos + 100}, size={160,20}, proc=vbwVS, value=vbwBeginVSV, title="VBW begin:", disable=(1), limits={0,1, .01} 
	SetVariable vbwEndVS pos={xPos, yPos + 125}, size={160,20}, proc=vbwVS, value=vbwEndVSV, title="VBW end:", disable=(1), limits={0,1, .01} 
	SetVariable mscoreBeginVS pos={xPos, yPos + 150}, size={160,20}, proc=mscoreVS, value=mscoreBeginVSV, title="Mscore begin:", disable=(1), limits={0,1, .01}
	SetVariable mscoreEndVS pos={xPos, yPos + 175}, size={160,20}, proc=mscoreVS, value=mscoreEndVSV, title="Mscore end:", disable=(1), limits={0,1, .01}
	SetVariable upBeginVS pos={xPos, yPos + 200}, size={160,20}, proc=upVS, value=upBeginVSV, title="Up begin:", disable=(1), limits={0,1, .01}
	SetVariable upEndVS pos={xPos, yPos + 225}, size={160,20}, proc=upVS, value=upEndVSV, title="Up end:", disable=(1), limits={0,1, .01}
	SetVariable dnBeginVS pos={xPos, yPos + 250}, size={160,20}, proc=dnVS, value=dnBeginVSV, title="Down begin:", disable=(1), limits={0,1, .01}
	SetVariable dnEndVS pos={xPos, yPos + 275}, size={160,20}, proc=dnVS, value=dnEndVSV, title="Down end:", disable=(1), limits={0,1, .01}
	
	Button applyVS pos={xPos, yPos + 300}, size={buttonWidth, buttonHeight}, title="Apply", proc=applyVSProc, disable=(1), userdata=udata
	variable /G retainSettingsVSV = 0
	CheckBox retainSettingsVS pos={xPos, yPos + 327}, title="Retain view settings", proc=retainSettingsProc, disable=(1)
	Button restoreDefaultVS pos={xPos, yPos +350}, size={buttonWidth + 20, buttonHeight}, title="Restore Defaults", proc=restoreDefaultVSProc, disable=(1), userdata=udata
	
	// controls for graph panel (controls on right side of panel)
	udata = "target:smartConc0#smartConcDisplay;"
	Button resetZoom pos={xPos + 1045, yPos}, size={buttonWidth, buttonHeight}, title="Reset zoom", proc=resetZoomProc, userdata = udata, disable=(0)
	
	// recreate grpah button
	Button recreateGraphButton pos={xPos + 1045, yPos + 25}, size={buttonWidth, buttonHeight}, title="Rec. graph", proc=recreateGraphButtonProc, disable=(0)
	
	// output tab stuff
	// temp output button
	udata = ""
	Button outputButton, pos={xPos,yPos}, size={buttonWidth, buttonHeight}, title="Output", proc=outputPress, userdata = udata, disable=(1)
	
	// vbw vs log10int stuff
	// display area
	udata = ""
	left = 285
	top = 35
	right = 1045
	bottom = 325
	Display /W=(left, top, right, bottom) /HOST=smartConc0
	RenameWindow #, outputDisplay
	
	variable /G isValidOutput = 0
	// listbox to hold the waves
	Make /T /O outputTextWave = {"bn", "mbd", "spb", "bf", "ssn", "ssf", "tf", "inter", "intra"}
	Make /T /O /N=(0) outputListWave
	Duplicate /O /T outputTextWave, outputListWave
	Make /B /O /N=(9) outputSelWave

	ListBox outputDisplayBox, mode=2, proc=outputDisplayBoxProc, listwave=outputListWave, selwave=outputSelWave, pos={xPos, yPos+ 35}, size={listBoxWidth,listBoxHeight}
	ListBox outputDisplayBox, disable=(1)
	SetWindow smartConc0#outputDisplay, hide=(1)
	SetActiveSubWindow smartConc0#smartConcDisplay
	
	// button to graph selected wave
	Button outputGraphButton, pos = {xPos, yPos + 200}, size={buttonWidth, buttonHeight}, title="Graph", proc=outputGraphButtonProc, userdata = udata, disable=(1)
	
	// temp button to print selwave
	Button printSelWaveButton, pos={xPos, yPos + 240}, size={buttonWidth, buttonHeight}, title="Print SW", proc=printSelWaveButtonProc, disable=(1)
	// MISC
	// placing this here to make sure is defined for man wave
	string /G histoAxis = "histo"
	string /G upsAxis = "lower1"
	string /G downAxis = "lower2"
end

// function for UPDATE button
function updatePress(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct 
	
	string lwavename = stringbykey("listwave", B_Struct.userdata)
	string twavename = stringbykey("textwave", B_Struct.userdata)
	string swavename = stringbykey("selwave", B_Struct.userdata)
	
	if (B_Struct.eventcode == 2)
		WAVE /T twave = $twavename
		string wl = WaveList("*_ptb", ";", "")
		string wn = ""
		Variable i = 0, n = itemsinlist(wl)
		redimension/n=(n) $twavename
		for (i = 0; i < n; i+=1)
			wn = stringfromlist(i,wl)
			twave[i] = wn
		endfor
		Duplicate  /O /T twave, $lwavename
		Make /B /O /N=(n) $swavename
	endif
end

// takes a wave like 20161117eg1s8sw1t1_ptb changes whatever letter is in place of the 'e'
// to an s, removes whatever expensions might be in place
function /s changeLetter(string thiswaven)
	//                       date                    letter               group      gn                     series         sn                    sweep           swn             trace           tn            
	string regExp="([[:digit:]]+)([[:alpha:]])g([[:digit:]]+)s([[:digit:]]+)sw([[:digit:]]+)t([[:digit:]]+)_([[:alpha:]]+)"
	string datecode, letter, group, groupn, series, seriesn, sweep, sweepn, trace, tracen, ext
	variable out=0
	splitstring /E=(regExp) thiswaven, datecode, letter, groupn, seriesn, sweepn, tracen, ext

	return datecode + "s" + "g" + groupn + "s" + seriesn + "sw" + sweepn + "t" + tracen
end

function shufflePress(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	string lwavename = stringbykey("listwave", B_Struct.userdata)
	string twavename = stringbykey("textwave", B_Struct.userdata)
	string swavename = stringbykey("selwave", B_Struct.userdata)
	WAVE /T lwave = $lwavename
	WAVE /B swave = $swavename
	WAVE /T twave = $twavename
	
	if (B_Struct.eventcode == 2 && WaveDims(lwave) != 0)
		// grabs name of selected ptb
		// not creating a duplicate right now as it looks like intervalsFromTime does?
		// NOTE: only works with one ptb atm
		string s = ""
		variable i = 0
		variable n = numpnts(lwave)
		
		string selected_ptb = ""
		
		for( i=0; i<n; i+=1)
			if (swave[i] != 0)
				selected_ptb = twave[i]
				break
			endif
		endfor
		
		// make copy of the original data wave (non ptb version)
		string new_formatted_name = changeLetter(selected_ptb)
		string orig_formatted_name = replacestring("_ptb", selected_ptb, "")
		Duplicate /O $orig_formatted_name $new_formatted_name

		// make copy of the ptb with the name we want
		string new_formatted_ptb = new_formatted_name + "_ptb"
		Duplicate /O $selected_ptb $new_formatted_ptb

		// interval function
		// sends the copy of the ptb to intervalsFromTime(wn) -- this gives us our intervals that we will shuffle
		string intervals_to_shuffle = intervalsFromTime(selected_ptb)
		
		// shuffle function
		// should be giving us a new wave with shuffled intervals
		string shuffled_intervals = shuffleTD(intervals_to_shuffle)
		
		// interval -> ptb function
		string shuffled_ptb = TimeFromIntervals(shuffled_intervals)
		Duplicate /O $shuffled_ptb $new_formatted_ptb
		
		
		// calls smart_conc on the ptb created from the shuffled intervals
		// using the before/after parameters
		// NOTE: not doing any error checking here atm--assuming smart conc handled it and user didn't
		// 		fuss with it afterwards
		// 		consider doing error checking, etc. here again?
		NVAR before, after
		string shuffled_smartConcReturned = smartConc(new_formatted_ptb, before, after)
		
		// graph the two things together
		// NOTE: just hard coding graphing, will run into issues w/ view settings if 
		// 		don't rerun smart conc first/clear graph
	
		// resize original smart conc
		SVAR smartConcAxis
		string target = "smartConc0#smartConcDisplay"
		ModifyGraph /W=$target axisEnab($smartConcAxis) = {.55, 1}

		// graph shuffled		
		WAVE yw = $(new_formatted_name + "_scy")
		WAVE xw = $(new_formatted_name + "_scx")
		string /G shuffled_smart_conc_axis = "shuffledsmartConc"
		appendtograph /W=$target /L=$shuffled_smart_conc_axis yw vs xw
		ModifyGraph freePos($shuffled_smart_conc_axis)=0
		ModifyGraph /W=$target axisEnab($shuffled_smart_conc_axis) = {0, .45}
	endif

end

// function for SMART CONC button
function smartConcPress(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	string lwavename = stringbykey("listwave", B_Struct.userdata)
	string twavename = stringbykey("textwave", B_Struct.userdata)
	string swavename = stringbykey("selwave", B_Struct.userdata)
	WAVE /T lwave = $lwavename
	WAVE /B swave = $swavename
	WAVE /T twave = $twavename
		
	if (B_Struct.eventcode == 2 && WaveDims(lwave) != 0)
		NVAR isValidOutput, binenabled, vbwEnabled, mscoreEnabled, updnEnabled, mscorePresent, updnPresent, regionVBWEnabled
		vbwEnabled = 0
		regionVBWEnabled = 0
		variable prevMscoreEnabled, prevUpdnEnabled
		prevMscoreEnabled = mscoreEnabled
		prevUpdnEnabled = updnEnabled
		mscoreEnabled = 0
		updnEnabled = 0
		mscorePresent = 0
		updnPresent = 0
		isValidOutput = 0
		
		// reset the stuff related to mw
		NVAR gRadioVal2 = root:gRadioVal2
		
		gRadioVal2 = 1
		
		CheckBox cbSC, value = gRadioVal2 == 1
		CheckBox cbMW, value = gRadioVal2 == 2
		
		// activates control if proper thing is selected
		if (gRadioVal2 == 2)
			SetVariable PopupWaveSelectorSV3,disable=(0)
			Button PopupWS_Button0, disable=(0)
		endif
		
		if (gRadioVal2 != 2)
			SetVariable PopupWaveSelectorSV3, disable=(1)
			Button PopupWS_Button0, disable=(1)
		endif
		
		string udata = "target:"
		udata += "smartConc0#smartConcDisplay;"
		udata += "hw:;"
		Button calculate userdata = udata
		
		string s = ""
		variable i = 0
		variable counter
		variable n = numpnts(lwave)
		string target = stringbykey("target", B_Struct.userdata)
		
		//variables for splitting the strings
		string dataName = ""
		string strToSplit = ""
		string ending = "_ptb"
		string formDataNames = ""
		string /G smartConcReturned = ""
		
		for( i=0; i<n; i+=1)
			if (swave[i] != 0)
				strToSplit = twave[i]
				dataName = RemoveEnding(strToSplit, ending)
				formDataNames += dataName + ";"
				counter+=1
			endif
		endfor
		
		NVAR before
		NVAR after
		
		variable cont = -1
		variable mininterval = 2147483647
		variable j
		
		//loop through all of the files, finding the abs min
		for (j = 0; j < n; j+=1)
			if (swave[j] != 0)
				string temp = intervalsfromtime(twave[j])
				WAVE /B tempw = $temp
				WaveStats/Z /Q tempw
//				if (V_min < mininterval)
// 20170111 make sure mininterval is not zero! needs a better way to handle this problem
//
				if ( ( V_min < mininterval) && ( V_min > 0 ) )
					mininterval = V_min
				endif
			endif
		endfor
		
		//handles error checking
		do
			if (!(before > mininterval)) 
				break
			endif
			
			string warning = ""
			warning += "The before value you set is greater than the smallest interval from the data: " + num2str( mininterval )
//			20170907 changed to allow for auto settting for very small values
//			before = getparam("Warning",warning, truncateDP(mininterval, 3))
			before = getparam("Warning",warning, mininterval)	
		while (1)
		
		do 
			if(!(after > mininterval))
				break
			endif
			
			string warning2 = ""
			warning2 += "The after value you set is greater than the smallest interval from the data"
//			20170907 changed to allow for auto setting for very small values
//			after = getparam("Warning",warning2, truncateDP(mininterval, 3))
			after = getparam("Warning", warning2, mininterval)	
		while (1)
		
		//20170124 moved this stuff outside the below counter so if smartConc aborted, displays nothing rather than just part of the graph
		setactivesubwindow $target
				
		//emptying graph
		string wl = "", rwn = ""
		wl = tracenamelist(target,  ";" , 1 )
		variable item=0, nitems=itemsinlist(wl)

		if (nitems>0)
			do
				rwn = stringfromlist( item, wl )
				WAVE rw = $rwn
				removefromgraph $rwn 
				item+=1
			while(item<nitems)
		endif	
		
		// calls smartConc and graphs the results
		if (counter > 0)
			smartConcReturned = smartConc(formDataNames, before, after)
		
			if (cmpstr(smartConcReturned, "") != 0)
				string xwn = stringbykey("scx", smartConcReturned)
				string ywn = stringbykey("scy", smartConcReturned)
				string gapyn = stringbykey("gapy", smartConcReturned)
				string gapxn = stringbykey("gapx", smartConcReturned)

				Button neoVBWButton userdata = "target:smartConc0#smartConcDisplay;"
				Button neoVBWButton userdata += "sct:"
				Button neoVBWButton userdata += stringbykey("sct", smartConcReturned)
				Button neoVBWButton userdata += ";"
								
				WAVE yw = $ywn
				WAVE xw = $xwn
				WAVE gapy = $gapyn
				WAVE gapx = $gapxn
				
				setactivesubwindow $target
				
				//makes the gap
				string gapAxis = "gap"
				
				// checks the threshold, makes any changes needed
				NVAR gapThresholdV
				variable g_temp = numpnts(gapy)
				variable g_i
				// make changes where below threshold
				for (g_i = 0; g_i < g_temp - 1; g_i+= 1)
					// checks if distance between two points is < threshold, only makes changes if both points indicate gap
					if (gapx[g_i + 1] - gapx[g_i] < gapThresholdV && gapy[g_i + 1] == 1 && gapy[g_i] == 1)
						gapy[g_i] = 0
						gapy[g_i + 1] = 0
					endif
				endfor
	
				appendtograph /W=$target /R=$gapAxis gapy vs gapx
				ModifyGraph mode($gapyn)=5
				ModifyGraph rgb($gapyn)=(0,65535,65535)
				ModifyGraph hbFill($gapyn)=2
				ModifyGraph freePos($gapAxis)=0
				if (binenabled == 1)
					ModifyGraph axisEnab($gapAxis)={0,1}
				endif
				ModifyGraph axRGB(gap)=(65535,65535,65535)
				ModifyGraph tlblRGB(gap)=(65535,65535,65535)
				
				//makes the smartConced graph
				string /G smartConcAxis = "smartConc"
				appendtograph /W=$target /L=$smartConcAxis yw vs xw
				ModifyGraph freePos($smartConcAxis)=0
				NVAR retainSettingsVSV
				NVAR smartConcBeginVSV, smartConcEndVSV
				
				if (!binenabled)
					resizeWindows()
				endif
									
				ModifyGraph lblPosMode($smartConcAxis)=1
				
				if (binenabled == 1)
					addBins(smartConcReturned, target)
				endif
				
				Label bottom "Time (sec)"
				
				// adds sct to the output button userdata
				string twn = stringbykey("sct", smartConcReturned)
				Button outputButton, userdata = "sct: ", userdata += twn
				Button outputButton, userdata += "; "
				
				// seeds regions vbw table w/ values
				variable time_inc = gapx[numpnts(gapx) - 1]
				time_inc = ceil (time_inc / 4)
				
				WAVE /T names
				WAVE starts, ends
				
				starts[0] = 0
				starts[1] = time_inc
				starts[2] = 2 * time_inc
				starts[3] = 3 * time_inc
				
				ends[0] = time_inc
				ends[1] = 2 * time_inc
				ends[2] = 3 * time_inc
				ends[3] = inf
				
				names[0] = "temp0"
				names[1] = "temp1"
				names[2] = "temp2"
				names[3] = "temp3"
			endif
		endif
		updnEnabled = prevUpdnEnabled
		mscoreEnabled = prevMscoreEnabled
	endif
end

// function that handles the binning/graphing the binning 
function addBins(smartConcReturned, target)
	string smartConcReturned
	string target
	NVAR binsize
	
	// preliminary stuff for histogram
	string twn = stringbykey("sct", smartConcReturned)
	string gxn = stringbykey("gapx", smartConcReturned)
	string gyn = stringbykey("gapy", smartConcReturned)
	WAVE tw = $twn
	WAVE gx = $gxn
	WAVE gy = $gyn
	
	variable binzero = gx[0]
	variable numbins = ceil(gx[numpnts(gx) - 1]/binsize)
	
	string wn = ""
	variable iw = 0
	string bursts = "", bpx = "", bpy = ""
	string hwn= ""
	variable ih = 0
	
	if (numpnts(tw) > 0)
		hwn = twn + "_h" + num2str(binsize)
		Make /n=(numbins) /O $hwn
		WAVE hw = $hwn
		Histogram /B={binzero,binsize,numbins} tw, hw
// td 20170109: centering the bins
//		Histogram/C /B={binzero,binsize,numbins} tw, hw

	else 
		print "no data in: ", twn
	endif
	
//  highlights the bins that intersect with the gaps
	variable currentBinStart
	variable currentBinEnd
	variable currentGapStart
	variable currentGapEnd
	
	currentBinStart = binzero
	currentBinEnd = binzero + binsize
	
	string binindexwn = "binindex"
	Make /N=(numbins) /O $binindexwn
	WAVE binindexw = $binindexwn
	
	variable twavecounter = 0
	variable numbadbins = 0
	variable numGaps = (numpnts(gx) - 2) / 4
	variable gapsChecked = 1
	variable gapStartIndex = 2
	variable gapEndIndex = 3
	if (numGaps > 0)
		currentGapStart = gx[gapStartIndex]
		currentGapEnd = gx[gapEndIndex]
	endif
	
	// 20170122 added  && gy[gapStartIndex] == 1 && gy[gapEndIndex] == 1 to prevent highlighting where I made changes to gapy (for gap threshold stuff)
	// also added the if (numGaps > 0) to handle out of range indexing for gy if there are no gaps 
	if (numGaps > 0)
		variable i = 0
		for (i = 0; i < numbins; i+=1)
			// case if rightmost edge is in the gap
			if (currentBinEnd > currentGapStart && currentBinEnd <= currentGapEnd && gy[gapStartIndex] == 1 && gy[gapEndIndex] == 1)
				binindexw[twavecounter] = i
				twavecounter+=1
				numbadbins += 1
			
			// case if leftmost edge is in the gap
			elseif (currentBinStart >= currentGapStart && currentBinStart < currentGapEnd && gy[gapStartIndex] == 1 && gy[gapEndIndex] == 1)
				binindexw[twavecounter] = i
				twavecounter+=1
				numbadbins += 1
			
			//case if the gap is encapsulated by the bin
			elseif (currentBinStart <= currentGapStart && currentBinEnd >= currentGapEnd && gy[gapStartIndex] == 1 && gy[gapEndIndex] == 1)
				binindexw[twavecounter] = i
				twavecounter+=1
				numbadbins += 1
			endif
			
			currentBinStart = currentBinEnd
			currentBinEnd += binsize
			
			// controls which gap we are looking at
			if (currentBinStart >= currentGapEnd && gapsChecked < numGaps)
				gapStartIndex += 4
				gapEndIndex += 4
				currentGapStart = gx[gapStartIndex]
				currentGapEnd = gx[gapEndIndex]
				gapsChecked += 1
			endif
		endfor	
	endif
	
	//makes the histogram of bins
// 20170320 moved this to start to dodge error (see above note)
//	string /G histoAxis = "histo"
	SVAR histoAxis
	appendtograph /W=$target /L=$histoAxis hw
	NVAR binBeginVSV, binEndVSV, retainSettingsVSV
	resizeWindows()
	ModifyGraph freePos($histoAxis)=0
	//ModifyGraph mode($hwn) = 0
	ModifyGraph lsize($hwn) = 1
	ModifyGraph rgb($hwn) = (0, 0, 0)
	
//20170110 use bars instead of line
	ModifyGraph mode($hwn)=5,hbFill($hwn)=2
	
	
	// handles highlighting the bins containing the gaps
	variable j
	for (j = 0; j < numbadbins; j+=1)
		ModifyGraph rgb($hwn[binindexw[j]])=(65535,0,0)
	endfor

	string histoLabel = ""
	histoLabel += "Events per "
	histoLabel += num2str(binsize)
	histoLabel += " s"
	Label histo histoLabel
	ModifyGraph lblPosMode(histo)=2
	
	Button calculate userdata = "target:"
	Button calculate, userdata += "smartConc0#smartConcDisplay;"
	Button calculate, userdata += "hw:"
	Button calculate userdata += hwn
	Button calculate userdata += ";"	
	
	Button outputButton, userdata += "hw: "
	Button outputButton userdata += hwn
	Button outputButton, userdata += "; "
	
	resizeWindows()
end

// function for MAKE VBW GRAPH button
function vbwButtonProc(string target, string sctwn)
	NVAR vbwEnabled
	SVAR smartConcReturned
	 if (1)
	//if (vbwEnabled != 1)	
		NVAR regionVBWEnabled
		regionVBWEnabled = 0
		if (cmpstr(sctwn, "") == 0 || cmpstr(smartConcReturned, "") == 0)
			string warning = ""
			warning += "Please run Smart Conc before running Vary Burst Window"
			getparam("Error", warning, 0)
			vbwEnabled = 0
		
		else
			NVAR vbwmin
			NVAR vbwmax
			NVAR vbwint
			string dfName = "wavesFromAnalysis" 
			Button makeVbwTablesButton userdata=dfName
			DFREF oldtempDF = root:$dfName
			
			// emptying vbwgraph if there is one currently being displayed
			if (vbwEnabled == 1)
				string rwn
				string bpyWaves
				variable item = 0
				variable nitems
	
				setactivesubwindow $target
				setdatafolder root:$dfName
				bpyWaves = WaveList("*_bpy", ";", "")
				setdatafolder root:
				nitems = itemsinlist(bpyWaves)
				if (nitems > 0)
					do
						rwn = stringfromlist(item, bpyWaves)
						WAVE /SDFR=oldtempDF rw = $rwn
						removefromgraph /Z $rwn
						item += 1
					while (item < nitems)
				endif
			endif
			
			// empties output graph
			SetWindow smartConc0#outputDisplay, hide=(0)
			SetActiveSubWindow smartConc0#outputDisplay
			string wl3 = "", rwn3 = ""
			wl3 = tracenamelist("smartConc0#outputDisplay",  ";" , 1 )
			variable item3=0, nitems3=itemsinlist(wl3)
	
			if (nitems3>0)
				do
					rwn3 = stringfromlist( item3, wl3 )
					WAVE /SDFR=oldtempDF rw3 = $rwn3
					removefromgraph $rwn3 
					item3+=1
				while(item3<nitems3)
			endif
			SetWindow smartConc0#outputDisplay, hide=(1)
			SetActiveSubWindow $target

			// does the vbw analysis
			string wn = sctwn
			string junk = vbanalysis(wn, vbwmin, vbwmax, vbwint)
			
			print junk
			
			string citywn = stringbykey("city", junk)
			WAVE /Z /T cityw = $citywn
			variable ibw = 0, nbw = dimsize(cityw, 0)
			string bpxwn="", bpywn = ""
			setactivesubwindow $target

//				i'm excluding a + 1 from what this is in banalysis v0-5 as it seems theres a ""
//				at the end of the things that i don't want
//				was ceil, changed as had issue with the plus one when just running default on 
// 				the large clean test, but when changed to bw start to 2, had problems w/o 1
			variable zMax = floor((vbwmax - vbwmin) / vbwint) + 1
			
			// moves waves into a data folder
			
			// kills old data folder if it exists
			if (DataFolderExists(dfName))
				KillDataFolder $dfName
			endif
			
			NewDataFolder :$dfName
			//NewDataFolder /O :$dfName
			DFREF tempDF = root:$dfName
			
//				VERSION GRABBING WAVES FROM CITYW
			variable z = 0
			variable x = 0
			variable i = 0
			variable colonIndex
			Variable numWaves = itemsInList(junk)
			String name	

			string formCityWN = ""
//				grabs the bpx, bpy, bpz
			for (x = 0; x < 3; x+=1)
				for (z = 0; z < zMax; z+=1)
					name = cityw[z][x]
					formCityWN += name
					formCityWN += ";"
				endfor
			endfor
			
			moveWavesToDf(formCityWN, dfName)

//				formats out the names, moves to df
			junk = formatKS(junk)
			moveWavesToDF(junk, dfName)
			
			vbwEnabled = 1
			
			// graphs the city plot
			do
				// looks for waves in appropriate location
				bpxwn = cityw[ibw][0]
				bpywn = cityw[ibw][1]
				
				WAVE/SDFR=tempDF bpxw = $bpxwn
				WAVE/SDFR=tempDF bpyw = $bpywn

				// 20170111 moved out of if/then statement
				string /G vbwAxis = "vbw"
				
				if (waveexists(bpxw))
					appendtograph /W=$target /L=$vbwAxis bpyw vs bpxw
					modifygraph rgb($bpywn)=(0,0,0)						
					modifygraph lsize($bpywn)=4
				endif
				
				ibw += 1
			while (ibw < nbw)
			
			// view settings (orig in do if statement)
			SVAR histoAxis
			SVAR smartConcAxis
			NVAR binenabled
			NVAR binBeginVSV
			NVAR binEndVSV
			NVAR smartConcBeginVSV
			NVAR smartConcEndVSV
			NVAR vbwBeginVSV
			NVAR vbwEndVSV, retainSettingsVSV
			NVAR isValidOutput
			isValidOutput = 1
			resizeWindows()
			ModifyGraph freePos(vbw)=0
			SetAxis /A/R $vbwAxis
			Label $vbwAxis "Burst Window (sec)"
			ModifyGraph lblPosMode($vbwAxis)=1
			
			// show log10 graph
			string regions_wl = wn + ";"
			print regions_wl
			string logwl = log10intFromTimes( regions_wl ) // includes display
			variable binzero=-2
			variable nbins=400
			variable binsize=0.01 //25
			print logwl
			print burstHistoFunction( logwl, binzero, nbins, binsize )
		endif
	endif
end


// function for MAKE VBW GRAPH button
//\\/\/\/\/\/\/\/\/\////\\\\/\/\/\/\/\\/\/\/\/\/\/\/\/\
//\\/\/\/\/\/\/\/\/\////\\\\/\/\/\/\/\\/\/\/\/\/\/\/\/\
// BEGIN					REGIONS
//\\/\/\/\/\/\/\/\/\////\\\\/\/\/\/\/\\/\/\/\/\/\/\/\/\
//\\/\/\/\/\/\/\/\/\////\\\\/\/\/\/\/\\/\/\/\/\/\/\/\/\
// 20170111 regions enabled

function vbwButtonProc2(string target, string sctwn)
	NVAR vbwEnabled
	SVAR smartConcReturned
	 if (1) // ! ? ! ?
	//if (vbwEnabled != 1)	
		if (cmpstr(sctwn, "") == 0 || cmpstr(smartConcReturned, "") == 0)
			string warning = ""
			warning += "Please run Smart Conc before running Vary Burst Window"
			getparam("Error", warning, 0)
			vbwEnabled = 0
		
		else
			NVAR vbwmin
			NVAR vbwmax
			NVAR vbwint
			string dfName = "wavesFromAnalysis" 
			Button makeVbwTablesButton userdata=dfName
			DFREF oldtempDF = root:$dfName
			
			// emptying vbwgraph if there is one currently being displayed
			if (vbwEnabled == 1)
				string rwn
				string bpyWaves
				variable item = 0
				variable nitems
	
				setactivesubwindow $target
				setdatafolder root:$dfName
				bpyWaves = WaveList("*_bpy", ";", "")
				setdatafolder root:
				nitems = itemsinlist(bpyWaves)
				if (nitems > 0)
					do
						rwn = stringfromlist(item, bpyWaves)
						WAVE /SDFR=oldtempDF rw = $rwn
						removefromgraph /Z $rwn
						item += 1
					while (item < nitems)
				endif
			endif
			
			// empties output graph
			SetWindow smartConc0#outputDisplay, hide=(0)
			SetActiveSubWindow smartConc0#outputDisplay
			string wl3 = "", rwn3 = ""
			wl3 = tracenamelist("smartConc0#outputDisplay",  ";" , 1 )
			variable item3=0, nitems3=itemsinlist(wl3)
	
			if (nitems3>0)
				do
					rwn3 = stringfromlist( item3, wl3 )
					WAVE /SDFR=oldtempDF rw3 = $rwn3
					removefromgraph $rwn3 
					item3+=1
				while(item3<nitems3)
			endif
			SetWindow smartConc0#outputDisplay, hide=(1)
			SetActiveSubWindow $target

			string wn = sctwn

// 				20170116 moved to this location (from below/from within the region for loop)
//				kills old data folder if it exists
			if (DataFolderExists(dfName))
				KillDataFolder $dfName
			endif
			NewDataFolder/O :$dfName
			DFREF tempDF = root:$dfName

//\\//\\//\\//\\//\\//\\\//\\/\\//\\//\\//\\//\\//\\//\\//\\//\/\/\/\/\/\
// 20170111z  how to handle regions ?
// the goal is to split the wn into multiple arbitrary regions chosen by the user
// regions will be stored in a string somewhere and passed to the handler

// 20170112 now gets regions info directly from waves : names, starts, ends
			string region_wns = "names:names;starts:starts;ends:ends"

			string junk = "" //vbanalysis(wn, vbwmin, vbwmax, vbwint)

// loop over regions
			string names_wn = stringbykey( "names", region_wns )
			string starts_wn = stringbykey( "starts", region_wns )
			string ends_wn = stringbykey( "ends", region_wns )
			
			WAVE/T names = $names_wn
			WAVE starts = $starts_wn
			WAVE ends = $ends_wn
			
			if( !waveexists( names ) )
				print "regions info waves must exist prior to regions analysis. try again!"
				makeRegionsInfoWaves()
				abort
			endif
			
			string region_name = "", region_wn = "", regions_wl = ""
			variable this_start = 0, this_end = 0
			variable iregion = 0, nregions = numpnts( names )
			
			if( nregions <= 1)
				print "fill out the regions waves in the table. try again!"
				makeRegionsInfoWaves()
				abort
			endif
		
			string /G vbwAxis = "vbw"
			
			// makes text table/rgb table to keep track of the colorings
			Make /T /O /N=(nregions) region_wn_table
			Make /O /N=(nregions, 3) rgb_table
			
			for( iregion = 0; iregion < nregions; iregion += 1 )
				region_name = names[iregion] 
				// chop up wn
				region_wn = region_name + "_cct" // chopped concatenate?
				if( starts[ iregion ] == 0 )
					this_start = 0
				else
					findlevel/Q/P $wn, starts[ iregion ]
					this_Start = floor( V_levelx ) + 1
				endif
				findlevel/Q/P $wn, ends[ iregion ]
				this_end = floor( V_levelx ) 
				
				duplicate/O/R=(this_start, this_end) $wn, $region_wn
				
				// store regions wavenames
				regions_wl += region_wn+ ";"
				// stores wn in text table
				region_wn_table[iregion] = region_name
				
				junk = vbanalysis( region_wn, vbwmin, vbwmax, vbwint, force_name=region_name )

				string citywn = stringbykey("city", junk)
				WAVE /Z /T cityw = $citywn
				variable ibw = 0, nbw = dimsize(cityw, 0)
				string bpxwn="", bpywn = ""
				setactivesubwindow $target

				variable zMax = floor((vbwmax - vbwmin) / vbwint) + 1
				
//				VERSION GRABBING WAVES FROM CITYW
				variable z = 0
				variable x = 0
				variable i = 0
				variable colonIndex
				Variable numWaves = itemsInList(junk)
				String name	

				string formCityWN = ""
//				grabs the bpx, bpy, bpz
				for (x = 0; x < 3; x+=1)
					for (z = 0; z < zMax; z+=1)
						name = cityw[z][x]
						formCityWN += name
						formCityWN += ";"
					endfor
				endfor
				
				moveWavesToDf(formCityWN, dfName)

//				formats out the names, moves to df
				junk = formatKS(junk)
				moveWavesToDF(junk, dfName)
				
				NVAR regionVBWEnabled
				regionVBWEnabled = 1
				vbwEnabled = 1
				
				// pick the color for the region
				string colors = returnColors( iregion, nregions )
				print colors
				variable red = str2num( stringfromlist( 0 , colors ) )
				variable green = str2num( stringfromlist( 1 , colors ) )
				variable blue = str2num( stringfromlist( 2 , colors ) )

				rgb_table[iregion][0] = red
				rgb_table[iregion][1] = green
				rgb_table[iregion][2] = blue
				
				// graphs the city plot
				do
					// looks for waves in appropriate location
					bpxwn = cityw[ibw][0]
					bpywn = cityw[ibw][1]
					
					WAVE/SDFR=tempDF bpxw = $bpxwn
					WAVE/SDFR=tempDF bpyw = $bpywn
					
					if (waveexists(bpxw))
						appendtograph /W=$target /L=$vbwAxis bpyw vs bpxw
						modifygraph rgb($bpywn)=( red, green, blue ) // each region gets a unique color
						modifygraph lsize($bpywn)=4
					endif
					
					ibw += 1
				while (ibw < nbw)
				
			endfor  // this is the for loop over the regions
			
//				viewsettings orig in do if statement
			SVAR histoAxis
			SVAR smartConcAxis
			NVAR binenabled
			NVAR binBeginVSV
			NVAR binEndVSV
			NVAR smartConcBeginVSV
			NVAR smartConcEndVSV
			NVAR vbwBeginVSV
			NVAR vbwEndVSV, retainSettingsVSV
			NVAR isValidOutput
			isValidOutput = 1
			resizeWindows()
			ModifyGraph freePos(vbw)=0
			SetAxis /A/R $vbwAxis
			Label $vbwAxis "Burst Window (sec)"
			ModifyGraph lblPosMode($vbwAxis)=1
			
			// show log10 graph
			print regions_wl
			string logwl = log10intFromTimes( regions_wl ) // includes display
			variable binzero=-2
			variable nbins=400
			variable binsize=0.01 //25
			print logwl
			print burstHistoFunction( logwl, binzero, nbins, binsize )
		endif // if we have _sct to process

	endif // if 1 is true
end // end vbw regions proc2

//\\/\/\/\/\/\/\/\/\////\\\\/\/\/\/\/\\/\/\/\/\/\/\/\/\
//\\/\/\/\/\/\/\/\/\////\\\\/\/\/\/\/\\/\/\/\/\/\/\/\/\
// end 					REGIONS						end
//\\/\/\/\/\/\/\/\/\////\\\\/\/\/\/\/\\/\/\/\/\/\/\/\/\
//\\/\/\/\/\/\/\/\/\////\\\\/\/\/\/\/\\/\/\/\/\/\/\/\/\

function makeVbwTablesProc(s) : ButtonControl
	Struct WMButtonAction &s
	
	if (s.eventcode == 2)
		NVAR regionVbwEnabled, vbwEnabled
		string dfname = s.userdata
		//if (regionVbwEnabled)	
		// placeholder REVERT
		if (vbwEnabled)
			makevbwtables(dfname = dfname)
		else
			string warning = ""
			warning += "Please run VBW before generating output tables"
			getparam("Error", warning, 0)
		endif
	endif
end


// function that handles the calc button/actually does the cluster analysis stuff
function jcluster_buCalculate(s) : ButtonControl
	Struct WMButtonAction &s
	
	// 20170111 added /z to prevent debugger // and moved into event code if statement (no ref needed if no click)
	if (s.eventcode == 2)
		NVAR/Z gRadioVal = root:gRadioVal
		NVAR/Z gSQRTOvalue = root:gSQRTOvalue
		NVAR/Z gFixedValue = root:gFixedValue
		NVAR/Z gZeroTerminate = root:ZeroTerminate
		
//		for deciding to use cluster w/ smart conc stuff or manual wave. 2 = manual wave		
		NVAR gRadioVal2 = root:gRadioVal2
		print "gRadioVal2", gRadioVal2
		
		string mscorewn = "", wn_ups="", wn_dns="",	 thisAxis = "", thiswn = ""

		string hwn =  stringbykey("hw", s.userdata)
		if (cmpstr(hwn, "") == 0 && gRadioVal2 != 2)
			string warning = ""
			warning += "Please run Smart Conc with binning enabled before running Cluster"
			getparam("Error", warning, 0)
		else 	
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
			
			//controlinfo puWaveName
			// changed for allowing mw
			string wn
			if (gRadioVal2 != 2)
				wn = hwn
			else
				SVAR man_wave_name = root:man_wave_name
				wn = man_wave_name
				print "prewn", wn
				
				// resets the hwn in the userdata so as to make user go back through smartconc
				s.userdata = ReplaceStringByKey("hw", s.userdata, "")
				
				// resets sct for vbw and regions vbw so as to make user go back through smartconc
//				Button vbwButton userdata = "target:smartConc0#smartConcDisplay;"
//				Button vbwButton userdata += "sct:;"
//				Button vbwButton2 userdata = "target:smartConc0#smartConcDisplay;"
//				Button vbwButton2 userdata += "sct:;"
				Button neoVBWButton win=smartConc0, userdata="target:smartConc0#smartConcDisplay;"
				Button neoVBWButton win=smartConc0, userdata += "sct:"
				Button neoVBWButton win=smartConc0, userdata += ";"
				
				NVAR isValidOutput
				isValidOutput = 0
			endif
			
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
			switch(gRadioVal)
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
					errorValue = gSQRTOValue
					break
				case 6:
					//Global SD
					errorType = "Fixed"
					errorValue = gFixedValue
					break
				case 7:
					// user provided error wave // \\ // not implemented yet
					errorType = "Error Wave"
					print "in JP cluster: need code to move selected wave to error wave!"
					abort
					break
				default:
					print "switch ClusterMain, unaccounted for errortype code: ", gRadioVal
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
			outlist = ClusterMain(wn, nPeaks, nNadir, tScoreUp, tScoreDn, minPeak, halfLife, outScore, errorType, errorValue, zeroTerminate = gZeroTerminate)
			
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
			NVAR updnEnabled, mscoreEnabled, updnPresent, mscorePresent
			
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
				if (updnEnabled)
					AppendToGraph/R=$upAxis w_ups
					modifygraph rgb($wn_ups)=(0,65535,0), mode($wn_ups)=5, hbfill($wn_ups)=2 
					Label $upAxis "\\K(0,0,0) <UP"
					ModifyGraph axRGB($upAxis)=(65535,65535,65535),tlblRGB($upAxis)=(65535,65535,65535)
					ModifyGraph alblRGB($upAxis)=(65535,65535,65535)			
					ModifyGraph freePos($upAxis)=20
					updnPresent = 1
				endif
			endif
			string dnAxis = "lower2"
			if(strsearch( oldtraces, wn_dns, 1) < 0)
				if (updnEnabled)
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
				if (mscoreEnabled)
					AppendToGraph/R=$thisAxis thisw  // thisw contains the reference to Mscore
					setaxis $thisaxis, -tscoredn, tscoreup
					modifygraph rgb($thiswn)=(0,0,65535), mode($thiswn)=5, hbfill($thiswn)=2
					ModifyGraph zero($thisAxis)=1
					ModifyGraph freePos($thisAxis)=0
					Label $thisAxis "Mscore"
					ModifyGraph lblPos($thisAxis)=80
					Label $thisAxis "\\K(0,0,0) Mscore"	
					ModifyGraph freePos($thisAxis)=0	

					mscorePresent = 1
				endif
			endif
			
			oldtraces = tracenamelist("",";",1)
			string firsttrace = stringfromlist(0,oldtraces)
			if(!stringmatch( firsttrace, wn_results))
				reordertraces $firsttrace, {$wn_results}
			endif
			
			if (mscoreEnabled)
				string /G mscoreAxis = thisAxis
			endif
			if (updnEnabled)
				string /G downAxis = dnAxis
				string /G upsAxis = upAxis
			endif
			variable /G modifyHisto = 1
			resizeWindows()
			modifyHisto = 0	
			
			resizeWindows()
		endif
	endif
end

// function for APPLY button
function applyVSProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	if (B_Struct.eventcode == 2)
		string target = stringbykey("target", B_Struct.userdata)
		NVAR binenabled, vbwEnabled, mscoreEnabled, updnEnabled
		NVAR smartConcBeginVSV, smartConcEndVSV, binBeginVSV, binEndVSV, vbwBeginVSV, vbwEndVSV, mscoreBeginVSV, mscoreEndVSV, upBeginVSV, upEndVSV, dnBeginVSV, dnEndVSV
		SVAR vbwAxis, histoAxis, smartConcAxis, mscoreAxis, upsAxis, downAxis
		variable total = smartConcEndVSV - smartConcBeginVSV
		variable errorFound = 0
		string warning = ""
		// check that the begins are below the ends
		if (smartConcBeginVSV >= smartConcEndVSV)
			warning += "Smart Conc begin must be less than end"
			getparam("Warning",warning, 0)	
			errorFound = 1
		endif
		if (binBeginVSV >= binEndVSV)
			warning = "Bin begin must be less than end"
			getparam("Warning",warning, 0)
			errorFound = 1
		endif
		if (vbwBeginVSV >= vbwEndVSV)
			warning = "VBW begin must be less than end"
			getparam("Warning",warning, 0)
			errorFound = 1
		endif
		if (mscoreBeginVSV >= mscoreEndVSV)
			warning = "Mscore begin must be less than end"
			getparam("warning", warning, 0)
			errorFound = 1
		endif
		if (upBeginVSV >= upEndVSV)
			warning = "Up begin must be less than end"
			getparam("warning", warning, 0)
			errorFound = 1
		endif
		if (dnBeginVSV >= dnEndVSV)
			warning = "Down begin must be less than end"
			getparam("warning", warning, 0)
			errorFound = 1
		endif
		
		// check that values don't add up beyond 1
		if (binenabled)
			total += binEndVSV - binBeginVSV
		endif
		if (vbwEnabled)
			total += vbwEndVSV - vbwBeginVSV
		endif
		if (mscoreEnabled)
			total += mscoreEndVSV - mscoreBeginVSV
		endif
		if (updnEnabled)
			total += upBeginVSV - upEndVSV
			total += dnBeginVSV - dnEndVSV
		endif
		if (total > 1)
			warning = "For best results, the proportion each graph takes up should sum to 1"
			getparam("Warning",warning, 0)
		endif
		
		// resize the axes if no major errors found
		if (errorFound == 0)
			setactivesubwindow $target
//			print smartConcAxis
			ModifyGraph axisEnab($smartConcAxis)={smartConcBeginVSV, smartConcEndVSV}
			if (binenabled)
				ModifyGraph axisEnab($histoAxis)={binBeginVSV, binEndVSV}
			endif
			if (vbwEnabled)
				ModifyGraph axisEnab($vbwAxis)={vbwBeginVSV, vbwEndVSV}
			endif
			if (mscoreEnabled)
				ModifyGraph axisEnab($mscoreAxis)={mscoreBeginVSV, mscoreEndVSV}
			endif
			if (updnEnabled)
				ModifyGraph axisEnab($upsAxis)={upBeginVSV, upEndVSV}
				ModifyGraph axisEnab($downAxis)={dnBeginVSV, dnEndVSV}
			endif
		endif
	endif
end

function restoreDefaultVSProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	if (B_Struct.eventcode == 2)
//		print "default vs restored"
		
		string target = stringbykey("target", B_Struct.userdata)
		NVAR binenabled, vbwEnabled
		NVAR smartConcBeginVSV, smartConcEndVSV, binBeginVSV, binEndVSV, vbwBeginVSV, vbwEndVSV
		SVAR vbwAxis, histoAxis, smartConcAxis
		
		// smart conc
		if (!binenabled && !vbwEnabled)
			smartConcBeginVSV = 0
			smartConcEndVSV = 1
			binBeginVSV = 0
			binEndVSV = 1
			vbwBeginVSV = 0
			vbwEndVSV = 1
		endif
		
		// smart conc + bins
		if (binenabled && !vbwEnabled)
			smartConcBeginVSV = .5
			smartConcEndVSV = 1
			binBeginVSV = 0
			binEndVSV = .45
			vbwBeginVSV = 0
			vbwEndVSV = 1
		endif		
		
		// smart conc + vbw
		if (!binenabled && vbwEnabled)
			smartConcBeginVSV = .5
			smartConcEndVSV = 1
			binBeginVSV = 0
			binEndVSV = 1
			vbwBeginVSV = 0
			vbwEndVSV = .45
		endif
		
		// smart conc + vbw + binning
		if (binenabled && vbwEnabled)
			vbwBeginVSV = 0
			vbwEndVSV = .4
			binBeginVSV = .45
			binEndVSV = .7
			smartConcBeginVSV = .75
			smartConcEndVSV = 1
		endif
		
		setactivesubwindow $target
		
		ModifyGraph axisEnab($smartConcAxis)={smartConcBeginVSV, smartConcEndVSV}
		if (binenabled)
			ModifyGraph axisEnab($histoAxis)={binBeginVSV, binEndVSV}
		endif
		if (vbwEnabled)
			ModifyGraph axisEnab($vbwAxis)={vbwBeginVSV, vbwEndVSV}
		endif
	endif
end

function resetZoomProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventcode == 2)
		SVAR vbwAxis
		NVAR vbwEnabled
		string target = stringbykey("target", B_Struct.userdata)
		setactivesubwindow $target
		
		SetAxis /A
		if (vbwEnabled)	
			SetAxis /A /R $vbwAxis
		endif
	endif
end

function recreateGraphButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventcode == 2)
//		20170907
//		sets focus on the appropriate graph based on the tab
//		done to prevent issue of replicating the panel instead of the graph on the panel
		// placeholder
		NVAR SCTABS
		if (SCTABS)
			print "smart conc display active"
			SetActiveSubWindow smartConc0#smartConcDisplay
		else 
			print "output display active"
			SetActiveSubwindow smartConc0#outputDisplay
		endif
		recreatetopgraph2()
	endif
end

function selectAllPress(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventcode == 2) 
		string swavename = stringbykey("selwave", B_Struct.userdata)
		WAVE /B swave = $swavename
		variable n = numpnts(swave)
		variable i = 0
		
		for (i = 0; i < n; i += 1)
			swave[i] = 1
		endfor
	endif
end

function tabsproc(name, tab)
	string name
	variable tab
	variable SCtab = 0, VBWtab = 1, VStab = 3, CMtab = 2, Otab = 4
	NVAR SCTABS
	
	// sets the SCTABS
	if (tab == Otab)
		SCTABS = 0
	else
		SCTABS = 1
	endif
	
	// smart conc controls
	Button updateButton, disable=(tab != SCtab)
	Button smartConcButton, disable=(tab != SCtab)
	Button shuffleButton, disable=(tab != SCtab)
	SetVariable binSizeVar, disable=(tab != SCtab)
	CheckBox binEnabledBox, disable=(tab != SCtab)
	SetVariable beforeVar, disable=(tab != SCtab)
	SetVariable afterVar, disable=(tab != SCtab)
	Button selectAllButton, disable=(tab != SCtab)
	SetVariable gapThreshold, disable=(tab != SCtab)
	
	// list box containing waves
	ListBox ptbDisplayBox, disable=(tab != SCtab && tab != VBWtab && tab != CMtab)
	
	if (tab == VBWtab || tab == CMtab)
		ListBox ptbDisplayBox, disable=2	
	endif
	
	// window with graphs
	SetWindow smartConc0#smartConcDisplay, hide=(tab == Otab)
	
	// vbw controls
	SetVariable vbwmin, disable=(tab != VBWtab)
	SetVariable vbwmax, disable=(tab != VBWtab)
	SetVariable vbwint, disable=(tab != VBWtab)
	Button neoVBWButton disable=(tab != VBWtab)
	CheckBox cbNR disable=(tab != VBWtab)
	CheckBox cbWR disable=(tab != VBWtab)
	//Button vbwButton, disable=(tab != VBWtab)
	//Button vbwButton2, disable=(tab != VBWtab)
	SVAR nameswn, startswn, endswn //, vbwRegionTableName
	NVAR xPos, yPos
	SetWindow smartConc0#vbwRegionTable hide=(tab != VBWtab)
	SetActiveSubWindow smartConc0#smartConcDisplay
	Button makeVbwTablesButton disable=(tab != VBWtab)

	// view settings controls
	SetVariable smartConcBeginVS, disable=(tab != VStab)
	SetVariable smartConcEndVS, disable=(tab != VStab)
	SetVariable vbwBeginVS, disable=(tab != VStab)
	SetVariable vbwEndVS, disable=(tab != VStab)
	SetVariable binBeginVS, disable=(tab != VStab)
	SetVariable binEndVS, disable=(tab != VStab)
	Button applyVS, disable=(tab != VStab)
	Button restoreDefaultVS, disable=(tab != VStab)
	CheckBox retainSettingsVS, disable=(tab != VStab)
	SetVariable mscoreBeginVS, disable=(tab != VStab)
	SetVariable mscoreEndVS, disable=(tab != VStab)
	SetVariable dnBeginVS, disable=(tab != VStab)
	SetVariable dnEndVS, disable=(tab != VStab)
	SetVariable upBeginVS, disable=(tab != VStab)
	SetVariable upEndVS, disable=(tab != VStab)
	
	// graph controls
	Button resetZoom, disable=(tab == Otab)
	
	// locks user control depending on what graphs are present
	NVAR binenabled
	NVAR vbwEnabled
	
//	if (tab == VStab && binenabled != 1)
//		SetVariable binBeginVS, disable=2
//		SetVariable binEndVS, disable=2
//	endif
	
//	if (tab == VStab && vbwEnabled != 1)
//		SetVariable vbwBeginVS, disable=2
//		SetVariable vbwEndVS, disable=2
//	endif
	
	// cluster controls
	CheckBox cbSC, disable=(tab != CMtab)
	CheckBox cbMW, disable=(tab != CMtab)
	
	// still hides/unhides as normal, but also handles if it should be grayed out
	NVAR gRadioVal2 = root:gRadioVal2
	if (tab != CMtab)
		SetVariable PopupWaveSelectorSV3, disable=(tab != CMtab)
		Button PopupWS_Button0, disable=(tab != CMtab)
	elseif (tab == CMtab && gRadioVal2 != 2)
		SetVariable PopupWaveSelectorSV3, disable=(2)
		Button PopupWS_Button0, disable=(2)
	else 
		SetVariable PopupWaveSelectorSV3, disable=(0)
		Button PopupWS_Button0, disable=(0)
	endif
	
	CheckBox mscoreEnabledBox, disable=(tab != CMtab)
	CheckBox updnEnabledBox, disable=(tab != CMtab)
	CheckBox cbZeroTerminate, disable=(tab != CMtab )
	
	SetVariable numPointsPeak, disable=(tab != CMtab)
	SetVariable numPointsNadir, disable=(tab != CMtab)
	SetVariable tscoreIncrease, disable=(tab != CMtab)
	SetVariable tscoreDecrease, disable=(tab != CMtab)
	SetVariable minPeakSize, disable=(tab != CMtab)
	SetVariable minNadir, disable=(tab != CMtab)
	SetVariable halfLife, disable=(tab != CMtab)
	SetVariable outlierTscore, disable=(tab != CMtab)
	
	Button saveParamDef, disable=(tab != CMtab)
	Button calculate, disable=(tab != CMtab)
	Button viewResults, disable=(tab != CMtab)
	Button printResults, disable=(tab != CMtab)
	
	valdisplay nPeaks, disable=(tab != CMtab)
	valdisplay nNadirs, disable=(tab != CMtab)
	
	Button storeResults, disable=(tab != CMtab)
	Button recallResults, disable=(tab != CMtab)
	
	CheckBox cbGlobalSD, disable=(tab != CMtab)
	CheckBox cbGlobalSE, disable=(tab != CMtab)
	CheckBox cbLocalSD, disable=(tab != CMtab)
	CheckBox cbLocalSE, disable=(tab != CMtab)
	CheckBox cbSQRT, disable=(tab != CMtab)
	CheckBox cbFixed, disable=(tab != CMtab)
	CheckBox cbErrWave, disable=(tab != CMtab)
	SetVariable svSQRTOvalue, disable=(tab != CMtab)
	SetVariable svFixedValue, disable=(tab != CMtab)
	
	PopupMenu puErrWaveName, disable=(tab != CMtab)
	Button buUpdateErrWLPU, disable=(tab != CMtab)
	
	// output controls
	Button outputButton, disable=(tab != Otab)
	SetWindow smartConc0#outputDisplay, hide=(tab != Otab)
	Listbox outputDisplayBox, disable=(tab != Otab)
//	Button outputGraphButton, disable=(tab != Otab)
	// functionality was moved to listbox, leaving just for kicks and giggles
	Button outputGraphButton, disable=(1)
	
	// put the little box thing around the right graph if in output tab
	if (tab == Otab)
		SetActiveSubwindow smartConc0#outputDisplay
	endif
end

// takes in a keyed string and removes the keys, returning a list with just the wavenames
function /s formatKS(sToFormat)
	string sToFormat
	string formString = ""
	
	variable i = 0
	variable size = itemsinlist(sToFormat)
	string name = ""
	variable colonIndex = 0
	
	for (i = 0; i < size; i+=1)
		name = StringFromList(i, sToFormat)
		colonIndex = strsearch(name, ":", 0)
		name = name[colonIndex + 1, inf]
		formString += name
		formString += ";"
	endfor
	
	return formString
end

// right now just takes super basic list of wn (doesn't deal w/ multi dimension, have to 
// filter out the names from keyed strings, etc)
function moveWavesToDF(wn, dfName)
	string wn
	string dfName
	
	variable i = 0
	variable size = itemsinlist(wn)
	
	string name = ""
	
	// make new df if doesn't exist
	if (!DataFolderExists(dfName))
		NewDataFolder :$dfName
	endif

	DFREF tempDF = root:$dfName	
	for (i = 0; i < size; i+=1)
		name = StringFromList(i, wn)
		if(WaveExists($name))
			MoveWave root:$name, tempDF
		endif
	endfor
end

function mscoreEnabledBoxProc (ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	
	NVAR mscoreEnabled
	mscoreEnabled = checked
end

function updnEnabledBoxProc (ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	
	NVAR updnEnabled
	updnEnabled = checked
end

function resizeWindows()
	NVAR retainSettingsVSV
	NVAR binenabled, vbwEnabled, mscoreEnabled, updnEnabled, mscorePresent, updnPresent
	NVAR smartConcBeginVSV, smartConcEndVSV, binBeginVSV, binEndVSV, vbwBeginVSV, vbwEndVSV, mscoreBeginVSV, mscoreEndVSV, upBeginVSV, upEndVSV, dnBeginVSV, dnEndVSV
	SVAR/Z vbwAxis, histoAxis, smartConcAxis, mscoreAxis, downAxis, upsAxis, smartConcReturned
//20170111 added /z above to stop debugger
	NVAR gRadioVal2
	string target = "smartConc0#smartConcDisplay"	
	
	// if manually putting wave into cluster
	if (gRadioVal2 == 2)
		upBeginVSV = .06
		upEndVSV = .1
		dnBeginVSV = 0
		dnEndVSV = .04
		mscoreBeginVSV = .8
		mscoreEndVSV = 1
		binBeginVSV = 0
		binEndVSV = 1
		NVAR modifyHisto
		
		if (mscoreEnabled && mscorePresent)
			ModifyGraph /W=$target axisEnab($mscoreAxis) = {mscoreBeginVSV, mscoreEndVSV}
			binEndVSV = .75
		endif
		if (updnEnabled && updnPresent)
			ModifyGraph /W=$target axisEnab($upsAxis) = {upBeginVSV, upEndVSV}
			ModifyGraph /W=$target axisEnab($downAxis) = {dnBeginVSV, dnEndVSV}
			binBeginVSV = .15
		endif
		
		if (modifyHisto)
			ModifyGraph /W=$target axisEnab($histoAxis) = {binBeginVSV, binEndVSV}
		endif
	else
// 	smartconc enabled
//	smartconc, binning enabled
	if (binenabled == 1 && cmpstr(smartConcReturned, "") != 0)
		if (retainSettingsVSV == 0)		
			smartConcBeginVSV = .5
			smartConcEndVSV = 1
			binBeginVSV = 0
			binEndVSV = .45			
		endif
		ModifyGraph /W=$target axisEnab($histoAxis) ={binBeginVSV, binEndVSV}
		ModifyGraph /W=$target axisEnab($smartConcAxis)={smartConcBeginVSV,smartConcEndVSV}
	else
		if (retainSettingsVSV == 0)
			smartConcBeginVSV = 0
			smartConcEndVSV = 1
		endif
		if (cmpstr(smartConcReturned, "") != 0)
			ModifyGraph /W=$target axisEnab($smartConcAxis)={smartConcBeginVSV,smartConcEndVSV}
		endif
	endif

//	smartconc, vbw enabled
// smartconc, binning, vbw enabled
	if (binenabled && vbwEnabled && cmpstr(smartConcReturned, "") != 0)	
		if (retainSettingsVSV == 0)
			vbwBeginVSV = 0
			vbwEndVSV = .4
			binBeginVSV = .45
			binEndVSV = .7
			smartConcBeginVSV = .75
			smartConcEndVSV = 1
		endif
		
		ModifyGraph /W=$target axisEnab($vbwAxis) = {vbwBeginVSV, vbwEndVSV}
		ModifyGraph /W=$target axisEnab($histoAxis) = {binBeginVSV, binEndVSV}
		ModifyGraph /W=$target axisEnab($smartConcAxis) = {smartConcBeginVSV, smartConcEndVSV}
	elseif (!binenabled && vbwEnabled)
		if (retainSettingsVSV == 0)
			vbwBeginVSV = 0
			vbwEndVSV = .45
			smartConcBeginVSV = .5
			smartConcEndVSV = 1
		endif
		
		ModifyGraph /W=$target axisEnab($vbwAxis) = {vbwBeginVSV, vbwEndVSV}
		ModifyGraph /W=$target axisEnab($smartConcAxis) = {smartConcBeginVSV, smartConcEndVSV}
	endif

// smartconc, binning, mscore enabled
	if (binenabled && mscoreEnabled && !vbwEnabled && !updnEnabled && mscorePresent)
		if (retainSettingsVSV == 0)
			smartConcBeginVSV = .7
			smartConcEndVSV = 1
			binBeginVSV = 0
			binEndVSV = .40
			mscoreBeginVSV = .45
			mscoreEndVSV = .65
		endif
		ModifyGraph /W=$target axisEnab($smartConcAxis)={smartConcBeginVSV,smartConcEndVSV}
		ModifyGraph /W=$target axisEnab($histoAxis) ={binBeginVSV, binEndVSV}
		ModifyGraph /W=$target axisEnab($mscoreAxis) = {mscoreBeginVSV, mscoreEndVSV}
	endif
		
// smartconc, binning, updn enabled
	if (binenabled && updnEnabled && !mscoreEnabled && !vbwEnabled && updnPresent)
		if (retainSettingsVSV == 0)
			smartConcBeginVSV = .55
			smartConcEndVSV = 1
			binBeginVSV = .15
			binEndVSV = .5
			upBeginVSV = .06
			upEndVSV = .1
			dnBeginVSV = 0
			dnEndVSV = .04
		endif
		ModifyGraph /W=$target axisEnab($smartConcAxis)={smartConcBeginVSV,smartConcEndVSV}
		ModifyGraph /W=$target axisEnab($histoAxis) ={binBeginVSV, binEndVSV}
		ModifyGraph /W=$target axisEnab($upsAxis) = {upBeginVSV, upEndVSV}
		ModifyGraph /W=$target axisEnab($downAxis) = {dnBeginVSV, dnEndVSV}
	endif		

//	smartconc, binning, mscore and updn enabled
	if (binenabled && !vbwEnabled && mscoreEnabled && updnEnabled && updnPresent && mscorePresent) 
		if (retainSettingsVSV == 0)
			smartConcBeginVSV = .75
			smartConcEndVSV = 1
			binBeginVSV = .15
			binEndVSV = .45
			mscoreBeginVSV = .5
			mscoreEndVSV = .7
			upBeginVSV = .06
			upEndVSV = .1
			dnBeginVSV = 0
			dnEndVSV = .04
		endif
		ModifyGraph /W=$target axisEnab($smartConcAxis) = {smartConcBeginVSV, smartConcEndVSV}
		ModifyGraph /W=$target axisEnab($mscoreAxis) = {mscoreBeginVSV, mscoreEndVSV}
		ModifyGraph /W=$target axisEnab($histoAxis) = {binBeginVSV, binEndVSV}
		ModifyGraph /W=$target axisEnab($upsAxis) = {upBeginVSV, upEndVSV}
		ModifyGraph /W=$target axisEnab($downAxis) = {dnBeginVSV, dnEndVSV}
	endif	
		
// 	smartconc, binning, vbw, mscore enabled
	if (binenabled && vbwEnabled && mscoreEnabled && !updnEnabled && mscorePresent)
		if (retainSettingsVSV == 0)
			vbwBeginVSV = 0
			vbwEndVSV = .3
			binBeginVSV = .35
			binEndVSV = .55
			mscoreBeginVSV = .6
			mscoreEndVSV = .75
			smartConcBeginVSV = .8
			smartConcEndVSV = 1
		endif
		
		ModifyGraph /W=$target axisEnab($vbwAxis) = {vbwBeginVSV, vbwEndVSV}
		ModifyGraph /W=$target axisEnab($histoAxis) = {binBeginVSV, binEndVSV}
		ModifyGraph /W=$target axisEnab($mscoreAxis) = {mscoreBeginVSV, mscoreEndVSV}
		ModifyGraph /W=$target axisEnab($smartConcAxis) = {smartConcBeginVSV, smartConcEndVSV}
	endif

// smartconc, binning, vbw, updn enabled	
	if (binenabled && vbwEnabled && updnEnabled && !mscoreEnabled && updnPresent)
		if (retainSettingsVSV == 0)
			vbwBeginVSV = 0
			vbwEndVSV = .35
			binBeginVSV = .55
			binEndVSV = .75
			dnBeginVSV = .4
			dnEndVSV = .44
			upBeginVSV = .46
			upEndVSV = .5
			smartConcBeginVSV = .8
			smartConcEndVSV = 1
		endif
	ModifyGraph /W=$target axisEnab($vbwAxis) = {vbwBeginVSV, vbwEndVSV}
	ModifyGraph /W=$target axisEnab($histoAxis) = {binBeginVSV, binEndVSV}
	ModifyGraph /W=$target axisEnab($upsAxis) = {upBeginVSV, upEndVSV}
	ModifyGraph /W=$target axisEnab($downAxis) = {dnBeginVSV, dnEndVSV}
	ModifyGraph /W=$target axisEnab($smartConcAxis) = {smartConcBeginVSV, smartConcEndVSV}
	endif
	
// smartconc, binning, vbw, mscore, updn enabled		
	if (binenabled && vbwEnabled && updnEnabled && mscoreEnabled && mscorePresent && updnPresent)
		if (retainSettingsVSV == 0)
			vbwBeginVSV = 0
			vbwEndVSV = .2
			binBeginVSV = .36
			binEndVSV = .56
			dnBeginVSV = .23
			dnEndVSV = .27
			upBeginVSV = .29
			upEndVSV = .33
			mscoreBeginVSV = .59
			mscoreEndVSV = .79
			smartConcBeginVSV = .82
			smartConcEndVSV = 1
		endif
		ModifyGraph /W=$target axisEnab($vbwAxis) = {vbwBeginVSV, vbwEndVSV}
		ModifyGraph /W=$target axisEnab($histoAxis) = {binBeginVSV, binEndVSV}
		ModifyGraph /W=$target axisEnab($upsAxis) = {upBeginVSV, upEndVSV}
		ModifyGraph /W=$target axisEnab($downAxis) = {dnBeginVSV, dnEndVSV}
		ModifyGraph /W=$target axisEnab($smartConcAxis) = {smartConcBeginVSV, smartConcEndVSV}
		ModifyGraph /W=$target axisEnab($mscoreAxis) = {mscoreBeginVSV, mscoreEndVSV}
	endif	
	
	endif // outer if for radioval
end 

// sets up prompt for two numeric entries, returns keyed stringlist
// DO NOT PUT COLONS IN PROMPTTEXT! 
function/s jget2params(boxtitle,prompttext,defaultvalue,prompttext2,defaultvalue2)
	string boxtitle, prompttext, prompttext2
	variable defaultvalue,defaultvalue2
	variable input=defaultvalue, input2=defaultvalue2
	prompt input, prompttext
	prompt input2, prompttext2
	
	DoPrompt boxtitle, input, input2
	string output = prompttext + ":" + num2str(input) + ";" + prompttext2 + ":" + num2str(input2) + ";"
	return output  
end

function jgetparam(boxtitle,prompttext,defaultvalue)
	string boxtitle, prompttext
	variable defaultvalue
	variable input=defaultvalue
	prompt input, prompttext
	DoPrompt boxtitle, input
	return input  
end

// check proc for deciding one/table vbw on vbw tab
function vbwCheckProc(name, value)
	String name
	Variable value
	
	NVAR neoVBWButtonRVal = root:neoVBWButtonRVal
	
	strswitch (name)
		case "cbNR":
			neoVBWButtonRVal = 1
			break
		case "cbWR":
			neoVBWButtonRVal = 2
			break
	endswitch
	CheckBox cbNR, value = neoVBWButtonRVal == 1
	CheckBox cbWR, value = neoVBWButtonRVal == 2
end	

// check proc for top radio buttons on cluster tab
function checkProc2(name, value)
	String name
	Variable value
	
	NVAR gRadioVal2 = root:gRadioVal2
	
	strswitch (name)
		case "cbSC":
			gRadioVal2 = 1
			break
		case "cbMW":
			gRadioVal2 = 2
			break
	endswitch
	CheckBox cbSC, value = gRadioVal2 == 1
	CheckBox cbMW, value = gRadioVal2 == 2
	
	// activates control if proper thing is selected
	if (gRadioVal2 == 2)
		SetVariable PopupWaveSelectorSV3,disable=(0)
		Button PopupWS_Button0, disable=(0)
	endif
	
	if (gRadioVal2 != 2)
		SetVariable PopupWaveSelectorSV3, disable=(2)
		Button PopupWS_Button0, disable=(2)
	endif
end
		

// check proc for radio buttons in cluster
function checkProc(name, value)
	String name
	Variable value
	
	NVAR gRadioVal = root:gRadioVal
	
	strswitch (name)
		case "cbGlobalSD":
			gRadioVal= 1
			break
		case "cbGlobalSE":
			gRadioVal= 2
			break
		case "cbLocalSD":
			gRadioVal= 3
			break
		case "cbLocalSE":
			gRadioVal= 4
			break
		case "cbSQRT":
			gRadioVal= 5
			break			
		case "cbFixed":
			gRadioVal= 6
			break
		case "cbErrWave":
			gRadioVal= 7
			break
	endswitch
	CheckBox cbGlobalSD,value= gRadioVal==1
	CheckBox cbGlobalSE,value= gRadioVal==2
	CheckBox cbLocalSD,value= gRadioVal==3
	CheckBox cbLocalSE,value= gRadioVal==4
	CheckBox cbSQRT,value= gRadioVal==5
	CheckBox cbFixed,value= gRadioVal==6
	CheckBox cbErrWave,value= gRadioVal==7

end

function truncateDP(inValue,targetDP)
// targetDP is the number of decimal places we want
	Variable inValue, targetDP
	targetDP = round(targetDP)
	inValue = round(inValue * (10^targetDP)) / (10^targetDP)
	return inValue
end

function binEnabledBoxProc (ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	
	NVAR binenabled
	binenabled = checked
end

// button proc for making the vbw graph
function neoVBWButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventcode == 2)
		string sctwn = stringbykey("sct", B_Struct.userdata)
		string target = stringbykey("target", B_Struct.userdata)
		
		// decide which function to send to
		NVAR neoVBWButtonRVal
		if (neoVBWButtonRVal == 1)
			vbwButtonProc(target, sctwn)
		elseif(neoVBWButtonRVal == 2)
			vbwButtonProc2(target, sctwn)
		endif
	endif
end

// function for OUTPUT button
function outputPress(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventcode == 2)
		print "This doesn't do anything right now"
//		print B_Struct.userdata
//		
//		print "testing"
//		
//		SaveGraphCopy /I /O as "testing"
	endif
end

function printSelWaveButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	if (B_Struct.eventcode == 2)
		WAVE /B swave = outputSelWave
		
		ControlInfo /W=smartConc0 outputDisplayBox
		print "V_Value: ", V_Value
	endif
end

// function for Graph button on output tab
function outputGraphButtonProc(B_Struct) : ButtonControl
	STRUCT WMButtonAction &B_Struct
	
	WAVE /T outputTWave = outputTextWave
	WAVE /T outputLWave = outputListWave
	WAVE /B outputSWave = outputSelWave
	
	if (B_Struct.eventcode == 2)
		DFREF df = root:wavesFromAnalysis
		
		
		//WAVE/SDFR=df/T names = $names_wn
		//WAVE/SDFR=df bww = $wn

		ControlInfo /W=smartConc0 outputDisplayBox
		variable index = V_Value
		
		SetDataFolder root:wavesFromAnalysis
		string sel_wl = ""
		string x_label = "Burst Window (sec)"
		string y_label = ""
		string suffix = ""
		// create wavelist for the selected type
		if (index == 0) 
			sel_wl = wavelist("*bn",";", "")
			y_label = "Number of Bursts"
			suffix = "_bn"
		elseif (index == 1)
			sel_wl = wavelist("*mbd",";", "")
			y_label = "Mean Burst Duration (sec)"
			suffix = "_mbd"
		elseif (index == 2)
			sel_wl = wavelist("*spb",";", "")
			y_label = "Num Spikes per Burst"
			suffix = "_spb"
		elseif (index == 3)
			sel_wl = wavelist("*bf",";", "")
			y_label = "Burst Frequency (hz)"
			suffix = "_bf"
		elseif (index == 4)
			sel_wl = wavelist("*ssn",";", "")
			y_label = "Number of Single Spikes"
			suffix = "_ssn"
		elseif (index == 5)
			sel_wl = wavelist("*ssf",";", "")
			y_label = "Single Spike Frequency (hz)"
			suffix = "_ssf"
		elseif (index == 6)
			sel_wl = wavelist("*tf",";", "")
			y_label = "Total Frequency (hz)"
			suffix = "_tf"
		elseif (index == 7)
			sel_wl = wavelist("*inter",";", "")
			y_label = "Inter Interval (sec)"
			suffix = "_inter"
		elseif (index == 8)
			sel_wl = wavelist("*intra",";", "")
			y_label = "Intra Interval (sec)"
			suffix = "_intra"
		endif 
		// create wavelist for the bww waves
		string bww_wl = wavelist("*bww", ";", "")
		SetDataFolder root:
		
		SetActiveSubwindow smartConc0#outputDisplay
		
		string oAxis = "outputAxis"
		
		// empty graph
		string wl = "", rwn2 = ""
		wl = tracenamelist("smartConc0#outputDisplay",  ";" , 1 )
		variable item2=0, nitems2=itemsinlist(wl)

		if (nitems2>0)
			do
				rwn2 = stringfromlist( item2, wl )
				WAVE rw2 = $rwn2
				removefromgraph $rwn2 
				item2+=1
			while(item2<nitems2)
		endif
		
		// graph the thing
		Wave /T rwn_table = region_wn_table
		Wave color_table = rgb_table
		variable num_regions = itemsinlist(bww_wl)
		// has the names with appropriate suffix
		Make /O /T /N=(num_regions) rwns_table
		
		// loop through each region 
			// grpah that sel wave vs bww wave
		variable i = 0
		// add suffixes to the rwn_table
		if (num_regions > 1)
			for (i = 0; i < num_regions; i+=1) 
				rwns_table[i] = rwn_table[i] + suffix
			endfor
		endif
		
		
		variable j = 0
		variable index2 = 0
		string sel_wn
		string bww_wn
		for (i = 0; i < num_regions; i+=1)
			sel_wn = stringfromlist(i, sel_wl)
			bww_wn = stringfromlist(i, bww_wl)
			WAVE /SDFR=df selectedWave = $sel_wn
			WAVE /SDFR=df bwwWave = $bww_wn
			appendtograph /W=smartConc0#outputDisplay /L=$oAxis selectedWave vs bwwWave
			
			if (num_regions > 1)
				// loop through the regions to find the appropriate index
				for (j = 0; j < num_regions; j += 1)
					if (!cmpstr(sel_wn, rwns_table[j]))
						index2 = j
					endif
				endfor
				
				modifygraph rgb($sel_wn)=(color_table[index2][0], color_table[index2][1], color_table[index2][2])
			endif
		endfor 

		Label $oAxis y_label
		Label bottom x_label
		ModifyGraph freePos($oAxis)=0
		ModifyGraph lblPosMode($oAxis)=2
	endif
end

function retainSettingsProc (ctrlName, checked) : CheckBoxControl
	string ctrlName
	variable checked
	
	NVAR retainSettingsVSV
	retainSettingsVSV = checked
end

function ptbDisplayBoxProc(ctrlName, row, col, event) : ListboxControl
	String ctrlName
	Variable row
	Variable col
	Variable event
end

function outputDisplayBoxProc(ctrlName, row, col, event) : ListboxControl
	String ctrlName
	Variable row
	Variable col
	Variable event
	
	if (event == 4)
		NVAR isValidOutput
		
		if (isValidOutput)
		
		DFREF df = root:wavesFromAnalysis
		
		
		//WAVE/SDFR=df/T names = $names_wn
		//WAVE/SDFR=df bww = $wn

		ControlInfo /W=smartConc0 outputDisplayBox
		variable index = V_Value
		
		SetDataFolder root:wavesFromAnalysis
		string sel_wl = ""
		string x_label = "Burst Window (sec)"
		string y_label = ""
		string suffix = ""
		// create wavelist for the selected type
		if (index == 0) 
			sel_wl = wavelist("*bn",";", "")
			y_label = "Number of Bursts"
			suffix = "_bn"
		elseif (index == 1)
			sel_wl = wavelist("*mbd",";", "")
			y_label = "Mean Burst Duration (sec)"
			suffix = "_mbd"
		elseif (index == 2)
			sel_wl = wavelist("*spb",";", "")
			y_label = "Num Spikes per Burst"
			suffix = "_spb"
		elseif (index == 3)
			sel_wl = wavelist("*bf",";", "")
			y_label = "Burst Frequency (hz)"
			suffix = "_bf"
		elseif (index == 4)
			sel_wl = wavelist("*ssn",";", "")
			y_label = "Number of Single Spikes"
			suffix = "_ssn"
		elseif (index == 5)
			sel_wl = wavelist("*ssf",";", "")
			y_label = "Single Spike Frequency (hz)"
			suffix = "_ssf"
		elseif (index == 6)
			sel_wl = wavelist("*tf",";", "")
			y_label = "Total Frequency (hz)"
			suffix = "_tf"
		elseif (index == 7)
			sel_wl = wavelist("*inter",";", "")
			y_label = "Inter Interval (sec)"
			suffix = "_inter"
		elseif (index == 8)
			sel_wl = wavelist("*intra",";", "")
			y_label = "Intra Interval (sec)"
			suffix = "_intra"
		endif 
		// create wavelist for the bww waves
		string bww_wl = wavelist("*bww", ";", "")
		SetDataFolder root:
		
		SetActiveSubwindow smartConc0#outputDisplay
		
		string oAxis = "outputAxis"
		
		// empty graph
		string wl = "", rwn2 = ""
		wl = tracenamelist("smartConc0#outputDisplay",  ";" , 1 )
		variable item2=0, nitems2=itemsinlist(wl)

		if (nitems2>0)
			do
				rwn2 = stringfromlist( item2, wl )
				WAVE rw2 = $rwn2
				removefromgraph $rwn2 
				item2+=1
			while(item2<nitems2)
		endif
		
		// graph the thing
		Wave /T rwn_table = region_wn_table
		Wave color_table = rgb_table
		variable num_regions = itemsinlist(bww_wl)
		// has the names with appropriate suffix
		Make /O /T /N=(num_regions) rwns_table
		
		// loop through each region 
			// grpah that sel wave vs bww wave
		variable i = 0
		// add suffixes to the rwn_table
		if (num_regions > 1)
			for (i = 0; i < num_regions; i+=1) 
				rwns_table[i] = rwn_table[i] + suffix
			endfor
		endif
		
		
		variable j = 0
		variable index2 = 0
		string sel_wn
		string bww_wn
		for (i = 0; i < num_regions; i+=1)
			sel_wn = stringfromlist(i, sel_wl)
			bww_wn = stringfromlist(i, bww_wl)
			WAVE /SDFR=df selectedWave = $sel_wn
			WAVE /SDFR=df bwwWave = $bww_wn
			appendtograph /W=smartConc0#outputDisplay /L=$oAxis selectedWave vs bwwWave
			
			if (num_regions > 1)
				// loop through the regions to find the appropriate index
				for (j = 0; j < num_regions; j += 1)
					if (!cmpstr(sel_wn, rwns_table[j]))
						index2 = j
					endif
				endfor
				
				modifygraph rgb($sel_wn)=(color_table[index2][0], color_table[index2][1], color_table[index2][2])
			endif
		endfor 

		Label $oAxis y_label
		Label bottom x_label
		ModifyGraph freePos($oAxis)=0
		ModifyGraph lblPosMode($oAxis)=2
		else
			// empty graph in case of leftovers
			string wl2 = "", rwn3 = ""
			wl2 = tracenamelist("smartConc0#outputDisplay",  ";" , 1 )
			variable item3=0, nitems3=itemsinlist(wl2)
	
			if (nitems3>0)
				do
					rwn3 = stringfromlist( item3, wl2 )
					WAVE rw3 = $rwn3
					removefromgraph $rwn3 
					item3+=1
				while(item3<nitems3)
			endif

			string warning = ""
			warning += "Please run Vary Burst Window before output"
			getparam("Error", warning, 0)
			
		endif // is valid output if
	endif
end

function binSizeVarProc(ctrlName, varNum, varStr, varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function vbwminSetVarProc (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function vbwmaxSetVarProc (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function vbwintSetVarProc (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function beforeSetVarProc (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function afterSetVarProc (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function vbwVS (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function smartConcVS (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function binVS (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function mscoreVS (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function upVS (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function dnVS (ctrlName, varNum, varStr, varName) :  SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
end

function cbZeroTerminateProc( s ) :  CheckBoxControl
STRUCT WMCheckBoxAction &s

end


/////////////////////////////////
function/S returnColors( item, nitems )
variable item, nitems

	variable ncolors=0, colorstep=0, mycolorindex=0
	string colortablename = "SpectrumBlack"
	make/o m_colors
	ColorTab2Wave $colorTableName
	duplicate/o m_colors, rainbowColors
	
	if(nitems > 1)
		ncolors = dimsize( RainBowColors, 0 )	
		colorstep = round( (ncolors-150) / (nitems-1) )
		wavestats/Q RainbowColors

		mycolorindex = round( item*colorstep )

		string colorout = ""
		colorout +=  num2str( rainbowcolors[mycolorindex][0] ) + ";"
		colorout +=  num2str( rainbowcolors[mycolorindex][1] ) + ";"
		colorout +=  num2str( rainbowcolors[mycolorindex][2] ) + ";"
	endif
	
return colorout // string list of color spec
end

////////////////////////////
function makeRegionsInfoWaves()

string nameswn = "names"
string startswn = "starts"
string endswn = "ends"

make/T/O/N=(1) $nameswn
make/O/N=(1) $startswn
make/O/N=(1) $endswn

edit /K=1 $nameswn, $startswn, $endswn

end

////////////////////////////////////////
// make tables of the output of region based VBW
function makeVBWtables( [dfname] )
string dfname
NVAR regionVbwEnabled, vbwEnabled

string dfn = "wavesFromAnalysis"
if( !paramisdefault( dfname ) )
	dfn = dfname
endif

variable useDF = 0
if( strlen( dfn ) > 0 ) // set the data folder
	DFREF df = root:$dfn
	Variable dfrStatus = DataFolderRefStatus(df)
	if (dfrStatus == 0)
		Print "makeVBWtables: Invalid data folder reference", dfn
		abort
	else
		useDF = 1
	endif	
endif
	
string analysis_types = "bn;mbd;spb;bf;ssn;ssf;tf;inter;intra;"
string names_wn = "names"

string ext = "", wn =""
string alt_name = ""
// names should be in the root
WAVE/T names = $names_wn
if( !waveexists( names ) )
	print "makeVBWtables: missing names! checking in df: ", names_wn, dfname
	WAVE/SDFR=df/T names = $names_wn
	if( !waveexists( names ) )
		print "makeVBWtables: still missing names! run Regions VBW! ", names_wn, dfname
		abort
	endif
endif
variable i=0
variable n
if (regionVbwEnabled)
	n=numpnts( names )
else
	n = 1
	setdatafolder root:$dfname
	alt_name = WaveList("*_bww", ";", "")
	setdatafolder root:
	// chop of _bww to get the actual name
	variable u_index = strsearch(alt_name, "_bww", 0)
	alt_name = alt_name[0, u_index - 1]
endif
variable j=0, m=itemsinlist( analysis_types )

for( j = 0 ; j < m ; j += 1 ) // loop over analysis types

	ext = stringfromlist( j, analysis_types )

	if (regionVbwEnabled)
		wn = names[0] + "_bww"
	else
		wn = alt_name + "_bww"
	endif
	
	if ( useDF )
		WAVE/SDFR=df bww = $wn
	else
		WAVE bww = $wn
	endif
	edit/K=1/n=$ext bww // first column is always the burst window
	
	for( i = 0 ; i < n ; i += 1 ) // loop over region names
		if (regionVbwEnabled)	
			wn = names[i] + "_" + ext
		else
			wn = alt_name + "_" + ext
		endif
		
		if ( useDF )
			WAVE/SDFR=df analysis = $wn
		else
			WAVE analysis = $wn
		endif
		
		if( waveExists( analysis ) )
			appendtotable analysis
		else
			print "makeVBWtables: missing analysis:", wn
			abort
		endif

	endfor // make a column for each region
	
endfor // make a table for each analysis type

end

Function testNotificationFunction(event, wavepath, windowName, ctrlName)
	Variable event
	String wavepath
	String windowName
	String ctrlName
	
	NVAR vbwEnabled, regionVbwEnabled
	vbwEnabled = 0
	regionVbwEnabled = 0
	Button neoVBWButton win=smartConc0, userdata = "target:smartConc0#smartConcDisplay;"
	Button neoVBWButton win=smartConc0, userdata += "sct:;"
	// invalidate stuff on output graph/remove it if it's there
	NVAR isValidOutput
	isValidOutput = 0
	
	// empty graph in case of leftovers
	string wl2 = "", rwn3 = ""
	SetWindow smartConc0#outputDisplay, hide=(0)
	wl2 = tracenamelist("smartConc0#outputDisplay",  ";" , 1 )
	variable item3=0, nitems3=itemsinlist(wl2)
	string target2 = "smartConc0#outputDisplay"
	if (nitems3>0)
		do
			rwn3 = stringfromlist( item3, wl2 )
			WAVE rw3 = $rwn3
			removefromgraph /W=$target2 $rwn3 
			item3+=1
		while(item3<nitems3)
	endif
	SetWindow smartConc0#outputDisplay, hide=(1)
	
	// doing this to prevent errors when selecting man wave after already having done one
	NVAR mscoreEnabled, mscorePresent, updnEnabled, updnPresent
	variable prev_mscoreEnabled = mscoreEnabled
	variable prev_updnEnabled = updnEnabled
	variable prev_mscorePresent = mscorePresent
	variable prev_updnPresent = updnPresent
	mscoreEnabled = 0
	mscorePresent = 0
	updnEnabled = 0
	updnPresent = 0
	
	print "Selected wave:",wavepath, " using control", ctrlName
	
	// empty graph if doing mw
	string target = "smartConc0#smartConcDisplay"
//	SetActiveSubWindow smartConc0#smartConcDisplay
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
	resizeWindows()
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
	
	resizeWindows()
	
	mscoreEnabled = prev_mscoreEnabled
	mscorePresent = prev_mscorePresent
	updnEnabled = prev_updnEnabled
	updnPresent = prev_updnPresent
end

// shamelessly stolen from http://www.igorexchange.com/node/1469
Function recreatetopgraph2([win,name,times])
	String win
	String name // The new name for the window and data folder. 
	Variable times // The number of clones to make.  Clones beyond the first will have _2, _3, etc. appended to their names.   
	if(ParamIsDefault(win))
//		win=WinName(0,1)
		string winl = WinList("*", ";", "WIN:65")
		win = stringfromlist(0,winl)
		GetWindow $win activeSW
		win=S_Value
	endif
	if(ParamIsDefault(name))
		name = UniqueName("copy", 11, 0)
	else
		name=CleanupName(name,0)
	endif
	times=ParamIsDefault(times) ? 1 : times
	String curr_folder=GetDataFolder(1)
	NewDataFolder /O/S root:$name
	String traces=TraceNameList(win,";",3)
	Variable i,j
	for(i=0;i<ItemsInList(traces);i+=1)
		String trace=StringFromList(i,traces)
		Wave TraceWave=TraceNameToWaveRef(win,trace)
		Wave /Z TraceXWave=XWaveRefFromTrace(win,trace)
		Duplicate /o TraceWave $NameOfWave(TraceWave)
		if(waveexists(TraceXWave))
			Duplicate /o TraceXWave $NameOfWave(TraceXWave)
		endif
	endfor
	String win_rec=WinRecreation(win,0)
	
	// removes /HOST=# so as to make the new thing a graph graph rather than a display
	// embedded in a panel like the original
	variable index_e = strsearch(win_rec, "/HOST=", 0)
	variable index_e2 = strsearch(win_rec, " ", index_e + 1)
	if (index_e != -1)
		win_rec = win_rec[0, index_e-1] + win_rec[index_e2, inf]
	endif
	
	// Copy error bars if they exist.  Won't work with subrange display syntax.  
	// NOTE: i have no clue if this is going to cause issues or anythign
	// 	   noen of the grpahs i was playing with had error bars
	for(i=0;i<ItemsInList(win_rec,"\r");i+=1)
		String line=StringFromList(i,win_rec,"\r")
		if(StringMatch(line,"*ErrorBars*"))
			String errorbar_names
			sscanf line,"%*[^=]=(%[^)])",errorbar_names
			for(j=0;j<2;j+=1)
				String errorbar_path=StringFromList(j,errorbar_names,",")
				sscanf errorbar_path,"%[^[])",errorbar_path
				String errorbar_name=StringFromList(ItemsInList(errorbar_path,":")-1,errorbar_path,":")
				Duplicate /o $("root"+errorbar_path) $errorbar_name
			endfor
		endif
	endfor
 
	for(i=1;i<=times;i+=1)
		//string window_name = UniqueName("copy", 6, 0)
		// just go based off of df name so graph and df always share name
		string window_name = name
		
		Execute /Q win_rec
		if(i==1)
			DoWindow /C $window_name
		else
			DoWindow /C $(window_name+"_"+num2str(i))
		endif
		ReplaceWave allInCDF
	endfor
	SetDataFolder $curr_folder
End