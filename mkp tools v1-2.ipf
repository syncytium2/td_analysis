#pragma rtGlobals=3		// Use modern global access method and strict wave access.


///////////////////////////////////
function/s buildmedian( wl, irow, nrows )
string wl // wave names to toss into the multidimensional array
variable irow, nrows // number of times we're running this

// user data keys: stores names of the output waves for each section
SVAR TC 		= 		mkp_TC 		//string/g mkp_TC = "TC"
SVAR SSAn 		= 		mkp_SSA 		// = "SSAn"
SVAR perm 		=		mkp_Perm
SVAR SSIn 		= 		mkp_SSI 		// = "SSIn"
SVAR Inact 		= 		mkp_SI 		// = "SIn"
SVAR RecIn 		= 		mkp_RI 		// = "RIn"

	// accumulate waves in table for median calculation
	variable item=0, nitems=itemsinlist( wl ), nwaves=0
	string itemn = "", wn = "", thiswaven = "", medwn=""

	string keylist = TC + ";" + perm + ";" + SSAn + ";" + SSIn + ";" + Inact + ";" + RecIn + ";" 
	string key="", list="", outlist=""
	string count=""
	variable icol=0, ncols = 0, iw=0
	for( item = 0; item < nitems; item +=1 ) // loop over the modeling items 
		key = stringfromlist( item, keylist )
	
		list = stringbykey( key, wl )
		nwaves = itemsinlist( list, "," )
		outlist += key + ":" 
		for(iw=0; iw<nwaves; iw+=1) // usually nwaves = 1, unless TC or multiple curves/voltages for SIRI
			thiswaven = stringfromlist( iw, list, "," )
			WAVE w = $thiswaven
			if( nwaves > 1)
				count = num2str(iw)
			else
				count = ""
			endif
			medwn = "m" + count + key
			outlist += medwn + ","
			ncols = numpnts( w )
			if( irow == 0 ) //!waveexists( medw ) ) // if there's no median wave, make one
				make/O/N=( nrows, ncols ) $medwn
				WAVE medw = $medwn
				medw = NaN
			endif
			WAVE medw = $medwn	
		//	medw[ irow ][] = w[p] // this notation should work, but it fails. only first element is set, the rest go to zero
		// brute force
			for( icol = 0; icol < ncols; icol += 1 ) // icol is the loop over data points in the data type, points on the activation curve
				medw[ irow ][ icol ] = w[ icol ]   // irow is the "cell"
				//print thiswaven, medwn, "irow:", irow, " icol:", icol, " sourcew:", w[icol], " medw:", medw[irow][icol]
			endfor
		endfor // loop over waves for each key
		outlist += ";" // terminate the CSV list within the ";" keyed list
	
	endfor // loop over data type TC SSA perm SSI SI RI

return outlist
end



///////////////////////
function/s calcMedian( wl, [templates, displayTC, nokill, domean] ) // wave list is a list of 2d arrays, rows are cells, columns are for median
string wl
string templates // keyed string wave list holding oringal data waves for scaling purposes
variable displayTC // if set, displays the traces and the median for this number
variable nokill // if set, saves the median box for other calculations
string domean // if set, use mean instead of median, be sure wl is named appropriately

string suffix = "m"
if( paramisdefault( domean ) )
	suffix = "median" // m for median
else
	suffix = domean // settable, should use "mean"
endif

// graph names from masterkinpanel
SVAR pn 		=		mkp_pann // panel name
SVAR SIRIdur	=		mkp_sSIRIduration
SVAR TC_gn 	= 		mkp_RealActSubg // time course graph name
SVAR SSA_gn 	= 		mkp_RealActProbg // activation graph name
SVAR SSI_gn 	=		mkp_RealInactProbg
SVAR SI_gn		=		mkp_RealSIprobg
SVAR RI_gn		=		mkp_RealRIProbg

SVAR TC 		= 		mkp_TC 		//string/g mkp_TC = "TC"
SVAR SSAn 		= 		mkp_SSA 		// = "SSAn"
SVAR perm 		=		mkp_Perm
SVAR SSIn 		= 		mkp_SSI 		// = "SSIn"
SVAR Inact 		= 		mkp_SI 		// = "SIn"
SVAR RecIn 		= 		mkp_RI 		// = "RIn"

string keylist = TC + ";" + perm + ";" + SSAn + ";" + SSIn + ";" + Inact + ";" + RecIn + ";" 

string key=""
string outlist = ""
variable iw=0, nw = itemsinlist( wl )
string mwn = "", twn="", mwl = ""
variable nCSV=0, iCSV=0, nanflag=0
variable irow=0, nrows = 0, icol=0, ncols = 0, dimmatch=0
for( iw = 0;  iw < nw ; iw += 1 )
	key = stringfromlist( iw, keylist )
	mwl = stringbykey( key, wl )
	nCSV = itemsinlist( mwl, "," )
	outlist +=  key + ":" 
	nanflag = 0
	for( iCSV=0; iCSV < nCSV; iCSV+=1 ) // loop over CSV from keyed string to handle multiple list items like TC
		mwn = stringfromlist( iCSV, mwl, "," )
		WAVE mw = $mwn
		if( waveexists( mw ) )
			nrows = dimsize( mw, 0 ) // rows are cells
			ncols = dimsize( mw, 1 ) // columns are data points
			make/O/N=(nrows) column
			make/O/N=(ncols) medianw
			for( icol = 0; icol < ncols; icol += 1 ) // loops over data points, e.g. activation curve
				for( irow = 0; irow < nrows; irow += 1 ) // loops over cells
					column[ irow ] =  mw[ irow ][ icol ] // transpose the matrix by columns, "cells"
				endfor
				if( paramisdefault( domean ) )
					medianw[ icol ] = StatsMedian( column )
					if( ( numtype(medianw[ icol ] ) != 0 ) && !nanflag )
						print "warning: NaN attack!", icol, icsv, iw
						nanflag = 1
					endif
				else
					wavestats/Z/Q column
					medianw[ icol ] = V_avg
				endif
			endfor
			mwn += suffix
			if( !paramisdefault( templates ) )
				twn = stringbykey( key, templates ) // get a data wave as a scaling template
				twn = stringfromlist( 0, twn, "," ) // the templates are keyed strings, each key identifies a potential comma separated list
				WAVE tw = $twn
				duplicate/O tw, $mwn
				WAVE outw = $mwn
				dimmatch = numpnts( outw )
				if( numpnts( medianw ) != dimmatch )
					redimension/N=(dimmatch) medianw
				endif 
				outw = medianw // should copy the scaling properties!
			else	
				duplicate/O medianw, $mwn
			endif
			if( paramisdefault( nokill ))
				killwaves/Z mw, column, medianw // clean up
			endif
		else  // if we're here, it's because there's no median box, mwn is not the name of a wave
			print "in calcmedian: no median box :: key:", key, "; mwn:", mwn
			//mwn += suffix // do nothing
		endif	
		outlist += mwn + ","
	endfor // loop over CSV
	outlist += ";" // terminate CSV 
endfor
// copy necessary xwaves from templates if available
string xkey = "", xwave=""
if(!paramisdefault( templates ))
	//print templates
	nw = itemsinlist( keylist )
	for( iw = 0;  iw < nw ; iw += 1 )
		key = stringfromlist( iw, keylist )
		// look for x version
		xkey = key + "x"
		
		xwave = stringbykey( xkey, templates )
		if( strlen( xwave ) > 0 )
			print "added xwave for median: xkey:",xkey,"; xwave: ",xwave
			outlist += xkey + ":" + xwave + ";"
		endif
	endfor
endif
return outlist
end


// loops over tabs to collect the relevant traces
function/s tracesbygraph( key, graphname, tabcontrolname )
string key
string graphname
string tabcontrolname

// possible keys
	SVAR TC 		= 		mkp_TC 		//string/g mkp_TC = "TC"
	SVAR SSAn 		= 		mkp_SSA 		// = "SSAn"
	SVAR perm 		=		mkp_Perm
	SVAR SSIn 		= 		mkp_SSI 		// = "SSIn"
	SVAR Inact 		= 		mkp_SI 		// = "SIn"
	SVAR RecIn 		= 		mkp_RI 		// = "RIn"
	
// current match list 911 make this the same!
string TCsuffix = ""
string SSAnsuffix = "_aPk_gGHK_n"
string permsuffix = "_aPk_p"
string SSInsuffix = "_iPk_n"
string InactSuffix = "_SIRI_n"
string recinsuffix = "_SIRI_n"

string keylist = TC + ";" + SSAn+ ";" + perm + ";" + SSIn + ";" + Inact + ";" + Recin + ";"
string suffixlist = TCsuffix + ";" + SSAnsuffix + ";" + permsuffix + ";" + SSInsuffix + ";" + Inactsuffix + ";" + Recinsuffix + ";"

string keyedcontrollist = ""
string svkey = "svkey", svlist=""
string graphkey = "graphkey", graphlist=""
string listboxkey = "listboxkey", listboxlist=""
string buttonkey = "buttonkey", buttonlist=""
string popupkey = "popupkey", popuplist=""
string rangekey = "rangekey", rangelist=""
string staticelementskey = "StaticElementsKey"
		
// get the current number of tabs
controlinfo $tabcontrolname
string tabcontroludata = S_userdata
string tablist = stringbykey( "tablist", tabcontroludata )
variable ntabs = itemsinlist( tablist, "," )

string tabname
string tabdata = ""			//getuserdata("", s.ctrlname, tabname) // gets named user data specific to the tab

string tnlist="", xtn="", stringstruct=""

//loop over tabs
variable itab=0, nt=0, itrace=0, flag = 0
string graphn = graphname
string trace="", tracelist="", outlist = ""

variable thiskey = whichlistitem( key, keylist )
string thissuffix = "*" + stringfromlist( thiskey, suffixlist )

for( itab=0; itab<ntabs; itab+=1 )
	tabname = stringfromlist( itab, tablist, "," )
	if( (stringmatch( tabname, "*median*" )==0) && (stringmatch( tabname, "*mean*")==0) ) // skip the median tab!

		tnlist = getuserdata( graphn, "", tabname ) // retrieve the trace list!
		tnlist = replacestring( ";", tnlist, "," )
		
		// screen tn list for extra traces, need only primary data
		nt = itemsinlist( tnlist, "," )
		itrace = 0
		flag = 0
		do
			trace = removequotes( stringfromlist( itrace, tnlist, "," ) )
			flag = stringmatch( trace, thissuffix )
			itrace += 1
		while( ( itrace < nt ) && ( flag == 0 ) ) // must end with suffix		
		if( flag == 0 )
			print "tracesbygraph: failed to get tracen", trace, thissuffix
		endif
			
		tracelist += trace  + "," // tnlist : only adding one trace per tab per graph at this time per key
		
		xtn = removequotes( getuserdata( graphn, "", tabname ) )
		
		stringstruct = getuserdata( graphn, "", tabname )
		
	endif
endfor
outlist = "traces:" + tracelist + ";" + "xwaven:" + xtn + ";" + "rangestruct:" + stringstruct + ":"
return outlist
end // tracesbykey


function/s getaxesinfoStruct( fullgraphname, s )
string fullgraphname // please provide full name including window#graphname
STRUCT graphsettings &s

//print "here i am"
//print "rockin like a hurricane"
//print fullgraphname

string axlist = axislist( fullgraphname )

if( whichlistitem( "bottom", axlist ) >= 0 )
	getAxis/Q /W=$fullgraphname bottom
	s.xmin = V_min
	s.xmax = V_max
endif
if( whichlistitem( "left", axlist ) >= 0 )
	getAxis/Q /W=$fullgraphname left
	s.ymin = V_min
	s.ymax = V_max
endif
//print s
string output = ""
structput/S s, output
return output
end //getaxesinfo 

/////////////////////////////////

// return wavelist based on tabs and analysis key, i.e. SSA

/////////////////////////////////
function/s keywavelist( key, tabctrlname )
string key // analysis key
string tabctrlname // name of the tab control with the desired tabs

	SVAR TC 		= 		mkp_TC 		//string/g mkp_TC = "TC"
	SVAR SSAn 		= 		mkp_SSA 		// = "SSAn"
	SVAR perm 		=		mkp_Perm
	SVAR SSIn 		= 		mkp_SSI 		// = "SSIn"
	SVAR Inact 		= 		mkp_SI 		// = "SIn"
	SVAR RecIn 		= 		mkp_RI 		// = "RIn"

	SVAR pann		= 		mkp_pann

	// graph names
	SVAR actg		=		mkp_Realactg			// = prefix + "Real", 
	SVAR actsubg	=		mkp_Realactsubg 		//= prefix + "subtracted", 
	SVAR actprobg	=		mkp_RealActProbg 		//= prefix + "prob"
	SVAR inactg		=		mkp_Realinactg 		//= prefix + "RealInact", 
	SVAR inactsubg	=		mkp_Realinactsubg 		//= prefix + "subtractedInact", 
	SVAR inactprobg =		mkp_RealinactProbg 	//= prefix + "prob"
	SVAR permg		=		mkp_permeabilityg 	//= prefix + "perm"
	SVAR SIg		=		mkp_RealSIg 			//= prefix + "RealSI", 
	SVAR SIsubg	=		mkp_RealSIsubg 		//= prefix + "subtractedSI", 
	SVAR SIprobg	=		mkp_RealSIprobg 	//= prefix + "SIprob"
	SVAR RIg		=		mkp_RealRIg 			//= prefix + "RealRI", 
	SVAR RIsubg	=		mkp_RealRIsubg 		//= prefix + "subtractedRI", 
	SVAR RIprobg	=		mkp_RealRIprobg 		//= prefix + "RIprob"
	// Sim // graph names
	//SVAR mkp_Simactg = prefix + "Sim", mkp_Simactsubg = prefix + "subtracted", mkp_SimActProbg = prefix + "prob"
	//SVAR mkp_Siminactg = prefix + "SimInact", mkp_Siminactsubg = prefix + "subtractedInact", mkp_SimInactProbg = prefix + "prob"
	//SVAR mkp_simSIg = prefix + "simSI", mkp_simSIsubg = prefix + "simSI", mkp_simSIprobg = prefix + "SIprob"
	//SVAR mkp_simRIg = prefix + "simRI", mkp_simRIsubg = prefix + "simRI", mkp_simRIprobg = prefix + "RIprob"
	
	string keylist = ""
	keylist 	= 		TC 		+ ";"
	keylist 	+= 		SSAn 	+ ";"
	keylist 	+= 		perm 	+ ";"
	keylist 	+= 		SSIn 	+ ";"
	keylist 	+= 		Inact 	+ ";"
	keylist 	+= 		Recin 	+ ";"
	
	//graph list in the same order!
	string graphlist = "", graphn = ""
	graphlist 	= 		actsubg 		+ ";" // this is where TC is plotted. don't ask how i know
	graphlist 	+=		actprobg 	+ ";"		// SSAn
	graphlist 	+= 		permg 		+ ";"			// perm
	graphlist 	+= 		inactprobg 	+ ";"	// inact
	graphlist 	+= 		SIprobg 	+ ";"		// SI
	graphlist 	+= 		RIprobg 	+ ";"		// RI
	
	string tl = ""
	// make sure the key is real
	variable which =  whichlistitem( key, keylist )
	if( which >= 0 )
		graphn = pann + "#" + stringfromlist( which, graphlist )
		string tabl = ""
		controlinfo  $tabctrlname
		tabl = stringbykey( "tablist", S_userdata )
		variable itab=0, ntabs = itemsinlist( tabl, "," )
		string tabname = ""
		for( itab=0; itab < ntabs; itab += 1 )
			tabname = stringfromlist( itab, tabl, "," )
			tl += getuserdata( graphn, "", tabname ) + ";"
		endfor
	endif
	tl = replacestring( ",", tl, ";" )  // just in case it's a CSV instead of ;SV ???
string output = tl
return output
end	
	
	
// to Prism 
// output to prism

function prism()

	SVAR TC 		= 		mkp_TC 		//string/g mkp_TC = "TC"
	SVAR SSAn 		= 		mkp_SSA 		// = "SSAn"
	SVAR perm 		=		mkp_Perm
	SVAR SSIn 		= 		mkp_SSI 		// = "SSIn"
	SVAR Inact 		= 		mkp_SI 		// = "SIn"
	SVAR RecIn 		= 		mkp_RI 		// = "RIn"

string key = "", keys = ""
// keys += TC + ";"
keys += SSAn + ";"
// keys += perm + ";"
keys += SSIn + ";"
keys += Inact + ";"
keys += RecIn + ";"
	
	// graph names from masterkinpanel
	SVAR pn 		=		mkp_pann // panel name
	SVAR SIRIdur	=		mkp_sSIRIduration
	SVAR TC_gn 	= 		mkp_RealActSubg // time course graph name
	SVAR SSA_gn 	= 		mkp_RealActProbg // activation graph name
	SVAR SSI_gn 	=		mkp_RealInactProbg
	SVAR SI_gn		=		mkp_RealSIprobg
	SVAR RI_gn		=		mkp_RealRIProbg
	
	SVAR svR1 = mkp_svR1

// get a list of cells from tabs
	string kList = "" //bs.userData
	string twoQubButton = "mkp_bu2qub"
	
	
	controlinfo FOO
	string tabname = S_value
	string udata = S_UserData
	string tablist = stringbykey( "tablist", udata )
	string wl = "", temp_path="temp", pathstring=""
	string medl = "" // string list to hold names of median tables
	
	variable itab=0, ntabs = itemsinlist( tablist, "," ), tabcount = 0
	for( itab = 0; itab < ntabs; itab += 1 )
		tabname = stringfromlist( itab, tablist, "," )
		if( (stringmatch( tabname, "*median*" )==0) && (stringmatch( tabname, "*mean*")==0) ) // skip the median tab!
			tabcount += 1
		endif
	endfor
	
	// panel name of mkp
	string target = "" 
	
	string graph_list = ""
	// graphnames to capture specific wavenames
	graph_list += "aPk:" + "PROB" + ";"
	graph_list += "perm:" + "PERM" + ";"
	graph_list += "aSS:" + "PROB" + ";"
	graph_list += "iPk:" + "PROB" + ";"
	graph_list += "SI:" + "SIPROB" + ";"
	graph_list += "RI:" + "RIPROB" + ";"	
		
	string outlist = ""
	// SSA
	outlist +=  SSAn + ":" 		// key for the wave name, i.e. 20170112as14_aPk_gGHK_n

	outlist += "intrinsic" + ","			// x wave

	outlist += "_aPk" + "," 					// table 1: raw
	outlist += "_aPk_gGHK" + "," 			// table 2: GHK conductance
	outlist += "_aPk_gGHK_n" + "," 		// table 3: GHK conductance normalized
	outlist += "_aPk_gGHK_nC" + "," 		// table 4: fit coefficients
	outlist += "_aPk_p" + "," 				// table 5: permeability
	outlist += "_aPk_tau" + "," 			// table 6: inactivation time constant, f(V)	
	
	outlist += "_aSS" + "," 					// table 7: steady state 
	outlist += "_aSS_gGHK" + "," 			// table 8: steady state 
	outlist += "_aSS_gGHK_n" + "," 		// table 9: steady state 	
	outlist += "_aSS_gGHK_nC" + "," 		// table 10: steady state 	
	outlist += "_aSS_p" + "," 				// table 11: steady state 
	outlist += "_aSS_tau" + "," 			// table 12: steady state 
	
	outlist += ";"// terminate the key!

	// SSI
	outlist += SSIn + ":"		// key
	
	outlist += "intrinsic" + ","			// x wave

	outlist += "_iPk" + ","					// table 13: 
	outlist += "_iPk_n" + ","				// table 14: 
	outlist += "_iPk_nC" + ","				// table 15: 
	outlist += "_iPk_tau" + ","				// table 16

	outlist += ";"// terminate the key!
	
	// SI
	outlist += Inact + ":" 		// key for the wavename

	outlist += "_SIRItiming_SIt" + "," 	// xwave

	outlist += "_SIRI_n" + ","				// table 17
	outlist += ";" // terminate the key!
	
	// RI
	outlist += RecIn + ":"		// key
	
	outlist += "_SIRItiming_RIt" + ","

	outlist += "_SIRI_n" + ","				// table 18
	outlist += ";" // terminate the key !
	
	string twn = "", wn = "",  ext = "", extlist = "", tablename = "", windowlist = ""
	variable iparam = 0, nparams = itemsinlist( keys )
	variable itable = 0, ntables = 0
	
	// loop over analyses
	for( iparam = 0; iparam < nparams; iparam += 1 )	
		
		key = stringfromlist( iparam, keys )
		extlist = stringbykey( key, outlist )
		
		ntables = itemsinlist( extlist, "," ) // first entry is the xwave
		
		for( itable = 1; itable < ntables; itable += 1 )
			
			ext = stringfromlist( itable, extlist, "," )
			tablename = key + ext
			windowlist = winlist( tablename, ";",  "WIN:2" )
			if( strlen( windowlist ) > 0 )
			else
				edit/k=1/N=$tablename
			endif				
			// loop over tabs / cells
			for( itab = 0; itab < ntabs; itab += 1 )
	
				tabname = stringfromlist( itab, tablist, "," )
	
				if( (stringmatch( tabname, "*median*" )==0) && (stringmatch( tabname, "*mean*")==0) ) // skip the median tab!
					
					klist = getuserdata( "", twoQuBButton, tabname ) 
					twn = stringbykey( key, klist )
					
					wn = datecodeGREP2( twn ) + "s" + num2str( seriesnumberGREP( twn ) ) + ext
					
					//print key, tabname, wn
					WAVE/Z w = $wn
					if( waveexists( w ) )
						appendtotable/W=$tablename $wn
					else
						//print "missing wave reference: ", wn
						// get the base extension, i.e. _aSS from _aSS_p
						variable pos = strsearch( ext, "_", 1 )  // 1 is start, first pos is always "_"
						variable it=0,nt = 0, condition = 0
						string extkey = "", graphn = "", tnlist = "", tn="", matchExtKey = ""
						if( pos > 1 )
							extkey = ext[1, pos - 1]
						else
							extkey = ext[1, inf]
						endif
						graphn = pn + "#" + stringbykey( extkey, graph_list )

						tnlist = getuserdata( graphn, "", tabname )
						nt = itemsinlist( tnlist )
						matchExtKey = "*" + extkey + "*"
						it=0
						do
							tn = stringfromlist( it, tnlist )
							condition = stringmatch( tn, matchExtKey ) 
							it+=1
						while( ( condition==0 ) && (it< nt ) )
					
						wn = datecodeGREP2( tn ) + "s" + num2str( seriesnumberGREP( tn ) ) + ext
					
						//print ext, extkey, graphn, tn, wn
						
						WAVE/Z w = $wn
						if( waveexists( w ) )
							appendtotable/W=$tablename $wn
						else
							print "prism: failed to get wn again: ", ext, extkey, graphn, tn, wn
						endif						

						// get the graph name for the extension
						// get the list of traces for the current tab
						// match a trace to the base extension
						// recreate wn
					endif
	
				endif
		
			endfor  // loop over tabs/cells
		
		endfor // loop over extension for each key
		
	endfor // loop over keys
		




// get a list of parameters,  SSA, SSI
string param_list = ""//"_aPk" + ";" // raw peak current
	// peak activation
param_list += "_aPk" + ";" 			// raw peak current
param_list += "_aPk_gGHK" + ";" 	// raw Clay conductance
param_list += "_aPk_gGHK_n" + ";" 	// norm Clay cond
param_list += "_aPk_p" + ";"		// raw permeability
	// steady state activation
param_list += "_aSS" + ";" 			// raw peak current
param_list += "_aSS_gGHK" + ";" 	// raw Clay conductance
param_list += "_aSS_gGHK_n" + ";" 	// norm Clay cond
param_list += "_aSS_p" + ";"		// raw permeability
	// inactivation
param_list += "_iPk" + ";" 			// raw inactivating
param_list += "_iPk_n" + ";" 		// norm peak current
	// SI
param_list += "_SIRI_n_SI" + ";" // raw peak current
	// RI
param_list += "_SIRI_n_RI" + ";" // raw peak current

// x waves
string xparam_list = ""
xparam_list += "aPk:" + "_aPk_gGHK_n_tx" + ";"
xparam_list += "aSS::" + "_aPk_gGHK_n_tx" + ";"
xparam_list += "iPk:" + "_iPk_n_tx" + ";"
xparam_list += "SI:" + "_SIRItiming_SIt" + ";"
xparam_list += "RI:" + "_SIRItiming_RIt" + ";"

// for each parameter, make a table with each column a cell
// first column should be x wave


end
