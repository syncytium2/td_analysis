#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma TextEncoding = "MacRoman"

//\\//\\//\\//\\//\\//\\//\\//\\

macro eventAnalysis( peaksign )
variable peaksign = -1	// sets optional parameter to determine sign of peak, +1 for positive, -1 for negative peak

// required parameters
variable m_rin = 0 		// disable input resistance measurement, only works for current clamp :: DO NOT SET TO 1 ::
variable use_csr = 0	 	// :: -1 use x-axis for range, :: 0 use default range -inf, inf sec, :: 1 use cursors A and B for range

// optional parameters in function call
variable trace 				// set tr = trace if you want to specify which trace, only use if multiple traces
variable baseline			// set bsl = baseline if you want to specify when the baseline measurement starts (5 msec dur)
variable xstart = -0.001, xend = inf				// set xs = xstart, xe = xend to specify a manual range for peak detection and analysis
variable peakwin = 0.01			// set pwin = peakwin, this sets the window to search for the peak if multiple peaks, starts at xstart 

print eventM( m_rin, use_csr, xs = xstart, xe = xend, pwin = peakwin, psign = peaksign )

endmacro

//\\//\\//\\//\\//\\//\\//\\//\\
// td version for averaged AMPA PSCs from blast_panel detection
//

macro AMPA_avePSCs( peaksign )
variable peaksign = -1	// sets optional parameter to determine sign of peak, +1 for positive, -1 for negative peak

// required parameters
variable m_rin = 0 		// disable input resistance measurement, only works for current clamp :: DO NOT SET TO 1 ::
variable use_csr = 0	 	// :: -1 use x-axis for range, :: 0 use default range -inf, inf sec, :: 1 use cursors A and B for range

// optional parameters in function call
variable trace 				// set tr = trace if you want to specify which trace, only use if multiple traces
variable baseline = -0.01			// set bsl = baseline if you want to specify when the baseline is taken
variable xstart = -0.002, xend = inf				// set xs = xstart, xe = xend to specify a manual range for peak detection and analysis
variable peakwin = 0.01			// set pwin = peakwin, this sets the window to search for the peak if multiple peaks, starts at xstart 

print eventM( m_rin, use_csr, bsl = baseline, xs = xstart, xe = xend, pwin = peakwin, psign = peaksign )

endmacro
//\\//\\//\\//\\//\\//\\//\\//\\
//  \\//\\//\\//\\//\\//\\//\\//\\

//
// td version for dcPSP analysis
//
//  \\//\\//\\//\\//\\//\\//\\//\\
//\\//\\//\\//\\//\\//\\//\\//\\

macro dcPSP()
variable peaksign = 1			// sets optional parameter to determine sign of peak, +1 for positive, -1 for negative peak

// required parameters
variable m_rin = 1 			// disable input resistance measurement, only works for current clamp :: DO NOT SET TO 1 unless you are pro ::
variable use_csr = 0	 		// :: -1 use x-axis for range, :: 0 use default range -inf, inf sec, :: 1 use cursors A and B for range

// optional parameters in function call
variable trace 					// set tr = trace if you want to specify which trace, only use if multiple traces
variable baseline	= 0.25	// set bsl = baseline if you want to specify when the baseline is taken

variable xstart = 0.4
variable xend = 0.5			// set xs = xstart, xe = xend to specify a manual range for peak detection and analysis

variable peakwin = 0.01		// set pwin = peakwin, this sets the window to search for the peak if multiple peaks, starts at xstart 

print eventM( m_rin, use_csr, bsl = baseline, xs = xstart, xe = xend, pwin = peakwin, psign = peaksign )

endmacro
//\\//\\//\\//\\//\\//\\//\\//\\
//  \\//\\//\\//\\//\\//\\//\\//\\

//
// td version for dcPSP analysis
//
//  \\//\\//\\//\\//\\//\\//\\//\\
//\\//\\//\\//\\//\\//\\//\\//\\

macro dcPSP_completo()
variable peaksign = 1			// sets optional parameter to determine sign of peak, +1 for positive, -1 for negative peak

	// required parameters
	variable m_rin = 1 			// disable input resistance measurement, only works for current clamp :: DO NOT SET TO 1 unless you are pro ::
	variable use_csr = 0	 		// :: -1 use x-axis for range, :: 0 use default range -inf, inf sec, :: 1 use cursors A and B for range
	
	// optional parameters in function call
	variable trace 					// set tr = trace if you want to specify which trace, only use if multiple traces
	variable baseline	= 0.25	// set bsl = baseline if you want to specify when the baseline is taken
	
	variable xstart = 0.3
	variable xend = 0.4			// set xs = xstart, xe = xend to specify a manual range for peak detection and analysis
	variable xinc = 0.01
	
	variable peakwin = 0.01		// set pwin = peakwin, this sets the window to search for the peak if multiple peaks, starts at xstart 
	string nm = "first_", holder=""
	string wlist = winlist("*", ";", ""), panelwin = stringfromlist( 0, wlist )
	string tablen = "dcPSPcompleto"
	variable imax = 11
	
	string pathn = "collector_data", passwn = "", passTablen="", targetwn = "", expcode = ""

	targetwn = removequotes( stringfromlist( 0, tracenamelist( "", ";", 1 ) ) )
	expcode = removequotes( datecodefromanything( targetwn ) )
	passTablen = "T_" + expcode + "_0"
	
	// 1st pulse
	holder = eventM( m_rin, use_csr, bsl = baseline, xs = xstart, xe = xend, xinc = xinc, pwin = peakwin, psign = peaksign, name = nm, tablen = tablen, maxseries = imax )
	
	xstart = 0.4
	xend = 0.5			// set xs = xstart, xe = xend to specify a manual range for peak detection and analysis
	xinc = 0.0
	peakwin = 0.01		// set pwin = peakwin, this sets the window to search for the peak if multiple peaks, starts at xstart 
	// 2nd pulse
	dowindow/F $panelwin
	nm = "second_"
	holder = eventM( m_rin, use_csr, bsl = baseline, xs = xstart, xe = xend, xinc = xinc, pwin = peakwin, psign = peaksign, name = nm, tablen = tablen, maxseries = imax )
	
	dowindow/F $panelwin

	passwn = passiveSandwich( setpathn = pathn, passiveTablen = passTablen, targetwn = targetwn ) // acts on top window!
	
	dowindow/F $tablen
	appendtotable/W=$tablen $passwn

	equilibrateTable()

endmacro
//\\//\\//\\//\\//\\//\\//\\//\\
//  \\//\\//\\//\\//\\//\\//\\//\\

//
// td version for dcPSP analysis
//
//  \\//\\//\\//\\//\\//\\//\\//\\
//\\//\\//\\//\\//\\//\\//\\//\\

macro dcPSP_1stpulse()
variable peaksign = 1			// sets optional parameter to determine sign of peak, +1 for positive, -1 for negative peak

// required parameters
variable m_rin = 1 			// disable input resistance measurement, only works for current clamp :: DO NOT SET TO 1 unless you are pro ::
variable use_csr = 0	 		// :: -1 use x-axis for range, :: 0 use default range -inf, inf sec, :: 1 use cursors A and B for range

// optional parameters in function call
variable trace 					// set tr = trace if you want to specify which trace, only use if multiple traces
variable baseline	= 0.25	// set bsl = baseline if you want to specify when the baseline is taken

variable xstart = 0.3
variable xend = 0.4			// set xs = xstart, xe = xend to specify a manual range for peak detection and analysis
variable xinc = 0.01

variable peakwin = 0.01		// set pwin = peakwin, this sets the window to search for the peak if multiple peaks, starts at xstart 
string nm = ""
print eventM( m_rin, use_csr, bsl = baseline, xs = xstart, xe = xend, xinc = xinc, pwin = peakwin, psign = peaksign, name = nm, tablen = "Test" )

endmacro

//\\//\\//\\//\\//\\//\\//\\//\\
//  \\//\\//\\//\\//\\//\\//\\//\\

//
// td version for dcPSP analysis
//
//  \\//\\//\\//\\//\\//\\//\\//\\
//\\//\\//\\//\\//\\//\\//\\//\\

macro dcPSP_2ndPulse()
variable peaksign = 1			// sets optional parameter to determine sign of peak, +1 for positive, -1 for negative peak

// required parameters
variable m_rin = 1 			// disable input resistance measurement, only works for current clamp :: DO NOT SET TO 1 unless you are pro ::
variable use_csr = 0	 		// :: -1 use x-axis for range, :: 0 use default range -inf, inf sec, :: 1 use cursors A and B for range

// optional parameters in function call
variable trace 					// set tr = trace if you want to specify which trace, only use if multiple traces
variable baseline	= 0.25	// set bsl = baseline if you want to specify when the baseline is taken

variable xstart = 0.4
variable xend = 0.5			// set xs = xstart, xe = xend to specify a manual range for peak detection and analysis
variable xinc = 0.0

variable peakwin = 0.01		// set pwin = peakwin, this sets the window to search for the peak if multiple peaks, starts at xstart 

print eventM( m_rin, use_csr, bsl = baseline, xs = xstart, xe = xend, xinc = xinc, pwin = peakwin, psign = peaksign )

endmacro



macro buildMKP()
	variable ntabs = 5
	buildmasterkinpanel( ntabs )
endmacro

macro passSandwich()
	string pathn = "collector_data"
	print passiveSandwich( setpathn = pathn )
endmacro


macro ap()

	variable trace = -1, smoothing = 10, threshold = 2
	threshold = getparam( "Derivative cutoff", "Enter derivative cutoff (V/s):", 2 )
	print appropV2_2( trace, smoothing, threshold, disp=2 )
	print threshold

end


macro makeBlastPanel()

	makeBPfunc()

end


macro refreshBlastPanel()

	refreshdetect()

end

macro refreshInt()
 
	refreshintervals()

end

macro refreshT50R( )
variable thissign = -1
variable disp = 1

refreshrisetimes( thissign, disp = 1 ) //, disp = 1 )

endmacro