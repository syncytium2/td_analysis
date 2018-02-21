#pragma rtGlobals=3		// Use modern global access method.
#pragma version=1.11
#pragma IgorVersion=6.20

#include <WaveSelectorWidget>

// **********************************
//	Documentation
//
//	This procedure file contains functions to turn a button, SetVariable control, or listbox cell into a popup
//	Wave Selector widget. It does this by creating a control panel, with action procedures and hook functions
//	when a button or list cell is clicked. The idea is to provide a data folder-aware way to select a wave in a control 
//	panel using a control that is similar to a popup menu control.
//
//	The emulation of a popup menu isn't perfect, especially in appearance. If you choose a button, the text is
// right-justified in the button with a down-pointing arrow at the right end. A too-long wave name will be clipped
// at the left end of the name; it does not use ellipsis (...) to indicate the truncation. It doesn't look quite like a 
//	popup menu button; it doesn't have the embossing around the menu arrow, and the text is not truncated with elipsis. A
//	real menu button left-justifies the text, but puts the arrow at the right.
//
//	If you use a SetVariable control, a small button with the down-pointing arrow is created and added at the right
//	end of your SetVariable control; this requires extra room to the right. It is somewhat more flexible than a button, but
// doesn't look as much like a menu. The selected wave name gets truncated at the right end, which is probably usually
//	the wrong end. 
//
//	You shuld set the SetVariable keyword noedit=1 for most purposes. If don't do this, the SetVariable text can be
// edited; it becomes something like a combo box in that case. I'm not sure that's very useful for wave selection!
//
//	To reduce the disjointed appearance of a SetVariable with a button, you can optionally request a group box with either a
//	3D-style or simple line to frame the SetVariable and button. It still looks kinda funny, but it is clearly a single
//	control group.
//
//	To use the popup wave selector, create either a button, SetVariable control, or listbox in your control panel. Then call
//	MakeButtonIntoWSPopupButton() for a button, MakeSetVarIntoWSPopupButton() for a SetVariable control, or MakeListboxCellIntoWSPopup()
// for a listbox cell. That's it- the code in this procedure file makes all the changes required for the control to function as a popup
//	wave selector.
//
//	If you use a listbox control, any cell that is made into a popup cell will have a down-pointing arrow at the right end
//	to indicate a popup is available there. Using a listbox allows you to provide an array or list of waves with user selection.
//	The text is right-justified in the cell so a too-long wave name will be truncated at the start of the name. Create a lisbox
//	with options that please you; then call MakeListboxCellIntoWSPopup() once for each cell you want to have a popup for.
//
//	Popup wave selectors communicate the selected wave name to your code via a notification function.
//	That is a function that you write which must have the correct function input parameters. These parameters
//	contain the information your code needs to identify which control was selected, and what wave was selected.
//	The selection for a listbox cell can also be read from your text listwave (see the listbox reference if this is mysterious).
//	The full path information is stored in a plane (the third dimension) of your listwave. The actual plane to use depends on what's
// already in the wave when you call MakeListboxCellIntoWSPopup(). You can access the correct plane using the dimension label 'WS_InfoPlane'.
//
//	For an example of both non-popup and popup wave selectors, peruse the example experiment:
//	File->Example Experiments->Programming->WaveSelectorWidgetExample.
//
//	Function Reference
//
//	----------------------
//	MakeButtonIntoWSPopupButton(hostWindow, hostButton, notifyProc [, initialSelection, globalString, popupWidth, popupHeight, options, content])
//
//		Function to turn a simple button into a popup wave selector.
//
//		hostWindow:		String containing the name of the control panel or graph window containing the button. This must be a 
//							full subwindow path if the button resides in a sub-window.
//		hostButton:		String containing the name of the button control.
//		notifyProc:		String containing the name of your notification function. See below for details on the notification function.
//		initialSelection	(Optional) String containing the full path for a wave to be selected when the control is first created.
//		globalString		(Optional) String containing the full path to a string variable. This variable will receive the name of the selected
//							wave. Note that this is of limited utility as it is just the wave's name without path.
//		popupWidth
//		popupHeight		Width and height in pixels of the popup control panel containing the wave selector. Defaults to 260 wide by 240 high.
//		options			(Optional) Set this to a sum of option constants:
//							PopupWS_OptionFloat			use a floating control panel as the popup panel. Otherwise,
//															a plain control panel is used.
//							PopupWS_OptionTitleInTitle	The button title is set by you; a down-pointing arrow is added to the end of your button title
//															to indicate that it is a popup button. If this option is not set, the selected wave name is
//															used as the button title.
//							other options apply only to a SetVariable control.
//		content			(Optional) parameter to select what is displayed in the list. A set of constants  
//							is provided for your convenience:							
//								WMWS_Waves			hierarchical display of waves in data folders
//								WMWS_DataFolders		hierarchical display of just the data folders
//							if absent, defaults to WMWS_Waves
//
//	----------------------
//	MakeSetVarIntoWSPopupButton(hostWindow, hostSetVar, notifyProc, globalString [, initialSelection, popupWidth, popupHeight, options, content])
//
//		Function to turn a SetVariable control into a popup wave selector. This function adds a small square button at the right
//		end and, optionally, a group box around both the SetVariable and the button.
//
//		hostWindow:		String containing the name of the control panel or graph window containing the SetVariablle control.
//							This must be a full subwindow path if the button resides in a sub-window.
//		hostSetVar:		String containing the name of the SetVariable control.
//		notifyProc:		String containing the name of your notification function. See below for details on the notification function.
//		globalString		String containing the full path to a string variable. This variable will receive the name of the selected
//							wave. Note that this is of limited utility as it is just the wave's name without path.
//		initialSelection	(Optional) String containing the full path for a wave to be selected when the control is first created.
//		popupWidth
//		popupHeight		Width and height in pixels of the popup control panel containing the wave selector. Defaults to 260 wide by 240 high.
//		options			(Optional) Set this to a sum of option constants:
//							PopupWS_OptionFloat			use a floating control panel as the popup panel. Otherwise,
//															a plain control panel is used.
//							PopupWS_OptionSVFramed		if you are using a SetVariable control, a group box will be
//															created surrounding the SetVariable.
//							PopupWS_OptionSVLineFrame	The group box will have a simple one-dimensional line appearance.
//															This option has effect only if PopupWS_OptionSVFramed is selected.
//		content			(Optional)  parameter to select what is displayed in the list. A set of constants  
//							is provided for your convenience:							
//								WMWS_Waves			hierarchical display of waves in data folders
//								WMWS_DataFolders		hierarchical display of just the data folders
//							if absent, defaults to WMWS_Waves
//
//	----------------------
//	MakeListboxCellIntoWSPopup(hostWindow, hostListbox, row, column, listWave, selWave [, notifyProc, initialSelection, popupWidth, popupHeight, options, content])
//
//		Function to turn a cell in a listbox control into a popup wave selector. This function adds a down-pointing arrow to the end of the cell text,
//		and sets the justification for the cell text to right-justified.
//
//		hostWindow:		String containing the name of the control panel or graph window containing the SetVariablle control.
//							This must be a full subwindow path if the button resides in a sub-window.
//		hostListbox:		String containing the name of the listbox control.
//		row, column:		The row number and column number of the cell to be used as a popup. You can make multiple calls to MakeListboxCellIntoWSPopup
//							to make multiple cells into popup cells.
//		listWave:			The text wave that sets the text for the listbox. This function adds a plane to the listWave with the dimension label 'WS_PathPlane'
//							to hold the full path to the selected wave. The displayed text will be just the name of the wave (or the existing cell text
//							if you set the PopupWS_OptionTitleInTitle option).
//		selWave:			The numeric wave set by the listbox keyword selWave. A plane is added to the wave with the dimension label 'WS_InfoPlane'
//							that is used by the popup code to keep private information.
//		notifyProc:		String containing the name of your notification function. See below for details on the notification function.
//		initialSelection:
//							Optional string containing the full path for a wave to be selected when the control is first created.
//		popupWidth:
//		popupHeight:		Width and height in pixels of the popup control panel containing the wave selector. Defaults to 260 wide by 240 high.
//		options:			Optional variable; set this to a sum of option constants:
//							PopupWS_OptionFloat			use a floating control panel as the popup panel. Otherwise,
//															a plain control panel is used.
//							PopupWS_OptionTitleInTitle	The cell text is set by you; a down-pointing arrow is added to the end of your cell text
//															to indicate that it is a popup cell. If this option is not set, the selected wave name is
//															used as the cell text.
//		content			(Optional)  parameter to select what is displayed in the list. A set of constants  
//							is provided for your convenience:							
//								WMWS_Waves			hierarchical display of waves in data folders
//								WMWS_DataFolders		hierarchical display of just the data folders
//							if absent, defaults to WMWS_Waves
//
//	----------------------
//	PopupWS_GetSelectionFullPath(hostWindow, ctrlName [, row, column])
//
//		Function to get the selected wave (or other string, see PopupWS_AddSelectableString). The return value
//		of the function is a string containing the full path or other string. May be "(no selection)".
//
//		hostWindow:		String containing the name of the control panel or graph window containing the SetVariablle control.
//							This must be a full subwindow path if the button resides in a sub-window.
//		ctrlName:			String containing the name of the button, SetVariable control, or listbox.
//		row, column:		(Optional) the row number and column number of the listbox cell to be used as a popup. Ignored if ctrlname
//							is not the name of a listbox.
//
//	----------------------
//	PopupWS_SetSelectionFullPath(hostWindow, ctrlName, fullPath [, row, column])
//
//		Function to set the selected wave (or other string, see PopupWS_AddSelectableString). Not much checking is done- you can set
//		the current selection to virtually anything.
//
//		hostWindow:		String containing the name of the control panel or graph window containing the SetVariablle control.
//							This must be a full subwindow path if the button resides in a sub-window.
//		ctrlName:			String containing the name of the button, SetVariable control, or listbox.
//		fullPath:			String containing the data folder path and wave name, properly single-quoted if names are liberal, to set the
//							current selection. May also be a "selectable string" (see PopupWS_AddSelectableString).
//		row, column:		(Optional) the row number and column number of the listbox cell to be used as a popup. Ignored if ctrlname
//							is not the name of a listbox.
//
//	----------------------
//	PopupWS_AddSelectableString(hostWindow, ctrlName, theString [, row, column])
//
//		Function to add an arbitrary string at the top of the WaveSelector. This is intended for adding items like "_calculated_".
//		See the related function WS_AddSelectableString in WaveSelectorWidget.ipf.
//
//		hostWindow:		String containing the name of the control panel or graph window containing the SetVariablle control.
//							This must be a full subwindow path if the button resides in a sub-window.
//		ctrlName:			String containing the name of the button, SetVariable control, or listbox.
//		theString:		The string to be added.
//		row, column:		(Optional) the row number and column number of the listbox cell to be used as a popup. Ignored if ctrlname
//							is not the name of a listbox.
//
//	----------------------
//	PopupWS_RemoveSelectableString(hostWindow, ctrlName, theString [, row, column])
//
//		Function to remove a string that was added via PopupWS_AddSelectableString(). 
//
//		hostWindow:		String containing the name of the control panel or graph window containing the SetVariablle control.
//							This must be a full subwindow path if the button resides in a sub-window.
//		ctrlName:			String containing the name of the button, SetVariable control, or listbox.
//		theString:		The string to be removed. Must match (case insensitive) a string that was previously added.
//		row, column:		(Optional) the row number and column number of the listbox cell to be used as a popup. Ignored if ctrlname
//							is not the name of a listbox.
//
//	----------------------
//	PopupWS_Move(hostWindow, ctrlName, newleft, newtop)
//
//		Function to move a popup wave selector. This is trivial for a button or listbox popup; you can simply use ModifyControl with
//		no ill effects. For a SetVariable style this function knows how to move the button and group box frame as well; the position
//		is the top-left corner of the SetVariable control.
//
//		hostWindow:		String containing the name of the control panel or graph window containing the button or SetVariable
//							control. This must be a full subwindow path if the button resides in a sub-window.
//		ctrlName:			String containing the name of the button or SetVariable control.
//		newleft:
//		newtop:			The left and top coordinates of the button or SetVariable control after it is moved.
//
//	----------------------
//	PopupWS_Resize(hostWindow, ctrlName, newWidth, newHeight)
//
//		Function to change the size of a popup wave selector. This is trivial for a button or listbox
//		control; you can simply use ModifyControl with no ill effects. For a SetVariable style this function knows how to 
//		move and resize the button and group box frame as well. 
//
//		hostWindow:	String containing the name of the control panel or graph window containing the button or SetVariable
//						control. This must be a full subwindow path if the button resides in a sub-window.
//		ctrlName:		String containing the name of the button or SetVariable control.
//		newWidth:
//		newHeight:	New dimensions of the control after re-sizing. If the control is a SetVariable, and the bodywidth 
//						is non-zero, this fact is detected and newWidth is a new value for bodyWidth rather than being used
//						as a new width with the size keyword.
//
//	----------------------
//	PopupWS_MatchOptions(hostWindow, ctrlName [, matchStr, listoptions, nameFilterProc])
//
//		Function to set wave name filtering options for the WaveSelectorWidget that will be popped up. The three optional
//		parameters are the same as the same-named parameters to MakeListIntoWaveSelector. If you call this function
//		without any of the optional parameters, it will re-set the wave name filtering to defaults. The input strings are passed
//		directly to a WaveSelector widget that is created for the popup control panel.
//
//		So far, this function applies to all the cells in a listbox control. There is presently no way to provide different filtering
// 		for different cells within a single listbox.
//
//		hostWindow:	String containing the name of the control panel or graph window containing the button or SetVariable
//						control. This must be a full subwindow path if the button resides in a sub-window.
//		ctrlName:		String containing the name of the button or SetVariable control.
//		matchStr:		optional parameter to select a subset of waves based on names and wildcards. See, for instance,
//						the WaveList() function for details. Default is "*" (match anything).
//		listoptions:	Optional parameter containing a string to be passed as the options parameter to the
//						WaveList() function. See documentation of WaveList(). The string is limited to 200 characters;
//						if the string is longer, PopupWS_MatchOptions returns PopupWS_ErrorStringTooLong
//						and does nothing. If listoptions is not set, it  defaults to "".
//		filterProcStr:
//						Optional parameter to name a function to filter objects before they are put into the list.
//						The function itself has the following format:
//
//							Function FilterProc(aName, contents)
//								String aName		// object name with full data folder path
//								Variable contents	// content code as described for the content parameter
//
//								return 0 to reject or 1 to accept
//							end
//
//						For example, to allow only objects starting with "w" (a trivial example that doesn't really
//						require a filter function):
//
//						Function MyFilter(aName, contents)
//							String aName
//							Variable contents
//							
//							String leafName = ParseFilePath(0, aName, ":", 1, 0)
//							if (CmpStr(leafName[0], "v") == 0)
//								return 1
//							endif
//							
//							return 0
//						end
//
//	----------------------
//	PopupWS_SetGetSortOrder(windowname, controlname, sortKindOrMinus1, sortReverseOrMinus1)
//		Sets or gets the sort ordering. sortKindOrMinus1 and sortReverseOrMinus1 are pass-by-reference.
//		controlname is the name of the host button, setvariable, or listbox.
//
//	----------------------
// You provide the name of a function that will be called when the user makes a selection from a popup. This is the only way to get this
// information when using a button; it is the only way to get the full data folder path to the selected wave when using a SetVariable control.
// It is optional when using a listbox cell; you can read the full path from listWave[row][column][%WS_PathPlane].
//
// The notification function for a button or SetVariable must look like this:
//
//	Function MyNotificationFunction(event, wavepath, windowName, ctrlName)
//		Variable event
//		String wavepath
//		String windowName
//		String ctrlName
//
//		Naturally, you can name it anything you want as long as it's a legal Igor function name :) The function may be static 
// 		if you include a module name. If it is in an independent module that isn't the one containing this code, it must also have an 
//		independent module name as part of the function name passed to MakeButtonIntoWSPopupButton or MakeSetVarIntoWSPopupButton.
//
//		Your function will be called with the parameters filled as follows:
//
//		event:			The event that caused the function to be called. WMWS_SelectionChanged is so far the only event. This
//						constant is defined in the WaveSelectorWidget.ipf procedure file.
//		wavepath:		String containing the full path of the selected wave. It is possible for this to have zero length if a click
//						didn't select a wave.
//		windowName:	String containing the name of the control panel or graph window containing the button or SetVariable
//						control. This is the window name passed by you into MakeButtonIntoWSPopupButton or 
//						MakeSetVarIntoWSPopupButton
//		ctrlName:		String containing the name of the button or SetVariable control.
//
// The notification function for a listbox must look like this:
//
//	Function MyNotificationFunction(event, wavepath, windowName, ctrlName, row, column)
//		Variable event
//		String wavepath
//		String windowName
//		String ctrlName
//		Variable row, column
//
//		This is just like the notification function for a button or SetVariable, with the addition of row, column parameters:
//
//		row, column:	the row and column of the listbox cell affected by the selection.
//
// Function PopupWS_SetPopupFont(hostWindow, ctrlName, [fontSize, fontStyle])
//		String hostWindow, ctrlName
//		Variable fontSize, fontStyle
//	
//		Sets the font size and/or font style for the listbox in the popup panel.
//
//		hostWindow:	String containing the name of the control panel or graph window containing the button or SetVariable
//						control. This must be a full subwindow path if the button resides in a sub-window.
//		ctrlName:		String containing the name of the button or SetVariable control.
//		fontSize:		Variable setting fontSize
//		fontStyle:		Variable setting fontStyle
// **********************************

// **********************************
// Version 1.0 first release
// Version 1.01 JP070306: PopupWSHostHook no longer pops up a hidden popup wave selector
//								Added popInfo.content=WMWS_DataFolders or WMWS_Waves.
//								MakeButtonIntoWSPopupButton(), etc takes optional Variable content	= one of WMWS_Waves or WMWS_DataFolders
// Version 1.02 JW 070320 Added PopupWS_SetGetSortOrder; just like WS_SetGetSortOrder in WaveSelectorWidget.ipf.
//								Allows client code to save and restore the sorting order of a popup wave selector.
//	Version 1.03 JW 070427 Fixed bugs: title-in-title buttons weren't.
//								Handle the renamed window event.
//	Version 1.04 JP 070814	Fixed bug in PopupWS_MatchOptions() (wrong sense of ParamIsDefault test for matchStr).
//								Adjusted popup panel sizes for native GUI on Mac.
//	Version 1.05 JW 070925	Strings added using WS_AddSelectableString() couldn't be selected.
//	Version 1.06 JW 071003	Altered the order of calls to Execute/P in waveSelectedNotifyProc() so that if the user's
//								notification proc calls Execute/P their command will run *after* mine.
//	Version 1.07 JW 080529	Fixed a bug: Popup window doesn't popup in the right place if the button or 
//								setvariable is in an external panel sub-window.
//	Version 1.08 JW 091006	Fixed bug: on Windows, fixed positioning of popup windows relative to controls, especially floating panel popups
//	Version 1.09 JW 100513	Changed required Igor version to 6.20 to accommodate rtGlobals=3
//								Added /Z to Execute/P/Q calls to avoid situations where a notification proc activates the main panel, triggering
//								more than one path to kill the popup control panel.
//	Version 1.10 JW 100708	Fixed bug: under some circumstances that I couldn't figure out (but which exist in the Multipeak Fit package mask and weight wave
//								menus) a click on the popup button after the popup panel was already showing would create the panel *below* the host panel
//								causing errors in the function that builds the popup panel. That second click now just cancels (kills the pre-existing popup panel).
//	Version 1.11 NH 
//								Fixed a bug where some "Button $hostButton, win=$hostWindow..." lines lacked the window specification.  Caused problems 
// 								any time the popupwaveselector was not on the top panel.  
//								Added the ability to set the font size and style of the listbox in the popup panel.  Did so by adding a fontSize and fontStyle variable 
//								to the PopupWaveSelctorInfo structure, including default 0s in the 3 constructor functions (Make*IntoWSPopup*), creating the
//								PopupWS_SetPopupFont(...) function and calling it from the panel creation function (fpopupWSPanel(...))
// **********************************

// **********************************
// Things to do
//
// **********************************

// constants to select appearance options
constant PopupWS_OptionFloat = 1
constant PopupWS_OptionSVFramed = 2
constant PopupWS_OptionSVLineFrame = 4
constant PopupWS_OptionTitleInTitle = 8

// constants for error codes returned by MakeButtonIntoWSPopupButton() and MakeSetVarIntoWSPopupButton()
Constant PopupWS_ErrorNoError = 0
Constant PopupWS_ErrorBadControl = 1
Constant PopupWS_ErrorNoGlobalStr = 2
// error code for PopupWS_MatchOptions
Constant PopupWS_ErrorStringTooLong = 3
// error codes for listboxes
Constant PopupWS_ErrorListWaveBadRows = 4
Constant PopupWS_ErrorListWaveBadColumns = 5
Constant PopupWS_ErrorSelWaveBadRows = 6
Constant PopupWS_ErrorSelWaveBadColumns = 7

// PRIVATE STUFF
static Constant MAX_OBJ_NAME = 31
static Constant WAVEPOPUPVERSION = 1.11

static Constant kPopMenuHeight = 17
static Constant kPopMenuMargin = 23

static StrConstant MenuArrowString = "\\W623"
static StrConstant Font9String="\\Z09"
static StrConstant RightJustString="\\JR"
static StrConstant NoSelectionString="(no selection)"

static Structure PopupWaveSelectorInfo
	int16		version
//	char		titleType										// 0: selection in title; 1: title in title
	char		doFloat
	char		hostWindow[100]
	char		hostButton[MAX_OBJ_NAME+1]
	char		hostSetVar[MAX_OBJ_NAME+1]
	char		NotificationProc[3*MAX_OBJ_NAME+3]
	Variable 	width
	Variable 	height
	Variable 	options
	Variable	SortKind
	Variable	SortOrder
	// 1.01 starts here
	Variable content	// if( popInfo.content) 1=WMWS_Waves,  4=WMWS_DataFolders
	// 1.11 starts here
	Variable fontSize
	Variable fontStyle
EndStructure

Function MakeButtonIntoWSPopupButton(hostWindow, hostButton, notifyProc [, initialSelection, globalString, popupWidth, popupHeight, options, content])
	String hostWindow, hostButton, notifyProc
	String initialSelection
	String globalString
	Variable popupWidth, popupHeight
	Variable options
	Variable content									// one of WMWS_Waves, WMWS_NVars, WMWS_Strings, or WMWS_DataFolders
	
	Variable TitleInTitle = 0			// selection is the title
	if (options & PopupWS_OptionTitleInTitle)
		TitleInTitle = 1
	endif
	
	ControlInfo/W=$hostWindow $hostButton
	if (V_flag != 1)
		return PopupWS_ErrorBadControl
	endif
	
	if (!ParamIsDefault(globalString))
		SVAR/Z gs = $globalString
		if (!SVAR_Exists(gs))
			return PopupWS_ErrorNoGlobalStr
		endif
	endif
	
	if (ParamIsDefault(popupWidth))
		popupWidth = 260
	endif
	
	if (ParamIsDefault(popupHeight))
		popupHeight = 240
	endif
	
	if (ParamIsDefault(initialSelection))
		initialSelection = NoSelectionString
	endif
	
	if (ParamIsDefault(content))
		content = WMWS_Waves
	endif
	
	STRUCT PopupWaveSelectorInfo popInfo
	popInfo.version = WAVEPOPUPVERSION
	popInfo.hostWindow = hostWindow
	popInfo.hostButton = hostButton
	popInfo.NotificationProc = notifyProc
	popInfo.width = popupWidth
	popInfo.height = popupHeight
	popInfo.SortKind = -1
	popInfo.SortOrder = -1
	popInfo.options = options
	if (options & PopupWS_OptionFloat)
		popInfo.doFloat = 1
	endif
	popInfo.content = content
	popInfo.fontSize = 0  // don't change it from default
	popInfo.fontStyle = 0 
	String infoStr
	StructPut/S popInfo, infoStr
	
	String titleString = RightJustString+Font9String+MenuArrowString
	if (TitleInTitle)
		ControlInfo/W=$hostWindow $hostButton
		Variable titlePos = strsearch(S_recreation, "title=\"", 0, 2)
		if (titlePos >= 0)
			titlePos += 7
			Variable titleEnd = strsearch(S_recreation, "\"", titlePos, 2)-1
			titleString = RightJustString+S_recreation[titlePos, titleEnd]+Font9String+MenuArrowString
		endif
	endif	
	
	Button $hostButton, win=$hostWindow, userData(popupWSInfo)=infoStr,proc=PopupWaveSelectorButtonProc
	Button $hostButton, win=$hostWindow,title=titleString
	if (SVAR_Exists(gs))
		Button $hostButton, win=$hostWindow, userData(popupWSGString)=globalString
	endif

	Wave/Z w=$initialSelection
	Variable isWave= WaveExists(w)
	Variable isDataFolder= DataFolderExists(initialSelection+":")	
	String str
	
	if (!TitleInTitle)
		if (isWave)
			str= NameOfWave(w)
		elseif(isDataFolder)
			str= initialSelection
		else
			str= NoSelectionString
		endif
		Button $hostButton, win=$hostWindow, title=RightJustString+str+" "+Font9String+MenuArrowString
	endif
	if (isWave)
		str= GetWavesDataFolder(w, 2)
	elseif(isDataFolder)
		str= initialSelection
	else
		str= NoSelectionString
	endif
	PopupWS_SetSelectionFullPath(hostWindow, hostButton, str)
	SetWindow $(StringFromList(0, hostWindow, "#")), hook(PopupWS_HostWindowHook)=PopupWSHostHook		// for the rename event

	return PopupWS_ErrorNoError
end

static structure SVdimensions
	Variable buttonleft
	Variable buttontop
	Variable buttonheight
	Variable buttonwidth
	Variable gbleft
	Variable gbtop
	Variable gbHeight
	Variable gbWidth
endstructure

static Function PopupWS_SVcalcDimensions(hostWindow, hostSetVar, lineFrame, svd)
	String hostWindow, hostSetVar
	Variable lineFrame
	STRUCT SVdimensions &svd
	
	ControlInfo/W=$hostWindow $hostSetVar
	svd.buttonleft=V_left+V_width-1
	svd.buttontop = V_top
	svd.buttonheight = V_height-1
	svd.buttonwidth = svd.buttonheight+1
	svd.gbleft= lineFrame ? V_left-3 : V_left-2
	svd.gbtop= V_top-2
	svd.gbHeight=lineFrame ? V_height+3 : V_height+4
	svd.gbWidth = V_width+V_height+4
end

Function MakeSetVarIntoWSPopupButton(hostWindow, hostSetVar, notifyProc, globalString [, initialSelection, popupWidth, popupHeight, options, content])
	String hostWindow, hostSetVar, notifyProc
	String globalString
	String initialSelection
	Variable popupWidth, popupHeight
	Variable options
	Variable content
	
	Variable frameit = (options&PopupWS_OptionSVFramed)!=0
	Variable lineFrame = (options&PopupWS_OptionSVLineFrame)!=0 

	ControlInfo/W=$hostWindow $hostSetVar
	if (abs(V_flag) != 5)
		return PopupWS_ErrorBadControl
	endif
	
	SVAR/Z gs = $globalString
	if (!SVAR_Exists(gs))
		return PopupWS_ErrorNoGlobalStr
	endif
	
	if (ParamIsDefault(popupWidth))
		popupWidth = 260
	endif
	
	if (ParamIsDefault(popupHeight))
		popupHeight = 240
	endif
	
	if (ParamIsDefault(initialSelection))
		initialSelection = NoSelectionString
	endif

	if (ParamIsDefault(content))
		content = WMWS_Waves
	endif
	
	SetVariable $hostSetVar,win=$hostWindow,noedit=1,value=$globalString,proc=PopupWSSetVarProc
	
	STRUCT SVdimensions svd
	PopupWS_SVcalcDimensions(hostWindow, hostSetVar, lineFrame, svd)
	
	String hostButton = "PopupWS_Button"
	hostButton = UniqueName(hostButton, 15, 0, hostWindow)
	Button $hostButton, win=$hostWindow, pos={svd.buttonleft, svd.buttontop},size={svd.buttonwidth, svd.buttonheight},title=Font9String+MenuArrowString,proc=PopupWaveSelectorButtonProc
	SetVariable $hostSetVar,win=$hostWindow,userdata(PopupWS_ButtonName)=hostButton
	if (frameit)
		String gboxName = "PopupWS_GroupBox"
		gboxName = UniqueName(gboxName, 15, 0, hostWindow)
		GroupBox $gboxName, win=$hostWindow, pos={svd.gbleft, svd.gbtop},size={svd.gbwidth, svd.gbheight}
		SetVariable $hostSetVar,win=$hostWindow,userdata(PopupWS_FrameName)=gboxName
		if (lineFrame)
			GroupBox $gboxName, win=$hostWindow, frame=0
		endif
	endif
	
	STRUCT PopupWaveSelectorInfo popInfo
	popInfo.version = WAVEPOPUPVERSION
	popInfo.hostWindow = hostWindow
	popInfo.hostButton = hostButton
	popInfo.hostSetVar = hostSetVar
	popInfo.NotificationProc = notifyProc
	popInfo.width = popupWidth
	popInfo.height = popupHeight
	popInfo.options = options | PopupWS_OptionTitleInTitle
	popInfo.SortKind = -1
	popInfo.SortOrder = -1
	if (options & PopupWS_OptionFloat)
		popInfo.doFloat = 1
	endif
	popInfo.content= content
	popInfo.fontSize = 0  // don't change it from default
	popInfo.fontStyle = 0 
	String infoStr
	StructPut/S popInfo, infoStr
	SetVariable $hostSetVar, win=$hostWindow, userData(popupWSInfo)=infoStr
	Button $hostButton, win=$hostWindow, userData(popupWSInfo)=infoStr,proc=PopupWaveSelectorButtonProc
	Button $hostButton, win=$hostWindow, title=Font9String+MenuArrowString
	Button $hostButton, win=$hostWindow, userData(popupWSGString)=globalString
	Button $hostButton, win=$hostWindow, userData(popupWSLastSelection)=globalString
	
	SetWindow $(StringFromList(0, hostWindow, "#")), hook(PopupWS_HostWindowHook)=PopupWSHostHook
	SetWindow $hostWindow, userData(PopupWS_SetVarList) += hostSetVar+";"
	
	Wave/Z w=$initialSelection
	Variable isWave= WaveExists(w)
	Variable isDataFolder= DataFolderExists(initialSelection+":")	
	String str
	if (isWave)
		str= GetWavesDataFolder(w, 2)
	elseif(isDataFolder)
		str= initialSelection
	else
		str= NoSelectionString
	endif
	PopupWS_SetSelectionFullPath(hostWindow, hostButton, str)

	return PopupWS_ErrorNoError
end

Function MakeListboxCellIntoWSPopup(hostWindow, hostListbox, row, column, listWave, selWave [, listboxproc, notifyProc, initialSelection, popupWidth, popupHeight, options, content])
	String hostWindow, hostListbox
	Variable row, column
	Wave/T listWave
	Wave selWave
	String listboxproc
	String notifyProc
	String initialSelection
	Variable popupWidth, popupHeight
	Variable options
	Variable content
	
	if (ParamIsDefault(notifyProc))
		notifyProc = ""
	endif
	
	Variable TitleInTitle = 0			// selection is the title
	if (options & PopupWS_OptionTitleInTitle)
		TitleInTitle = 1
	endif

	ControlInfo/W=$hostWindow $hostListbox
	if (V_flag != 11)
		return PopupWS_ErrorBadControl
	endif
	
	if (ParamIsDefault(popupWidth))
		popupWidth = 260
	endif
	
	if (ParamIsDefault(popupHeight))
		popupHeight = 240
	endif
	
	if (ParamIsDefault(initialSelection) && !TitleInTitle)
		initialSelection = NoSelectionString
	endif
	
	if (ParamIsDefault(listboxproc))
		listboxproc = ""
	endif
	
	if (ParamIsDefault(content))
		content = WMWS_Waves
	endif

	STRUCT PopupWaveSelectorInfo popInfo
	popInfo.version = WAVEPOPUPVERSION
	popInfo.hostWindow = hostWindow
	popInfo.hostButton = hostListbox
	popInfo.NotificationProc = notifyProc
	popInfo.width = popupWidth
	popInfo.height = popupHeight
	popInfo.SortKind = -1
	popInfo.SortOrder = -1
	popInfo.options = options
	if (options & PopupWS_OptionFloat)
		popInfo.doFloat = 1
	endif
	popInfo.content = content
	popInfo.fontSize = 0  // don't change it from default
	popInfo.fontStyle = 0
	String infoStr
	StructPut/S popInfo, infoStr
	
	if (FindDimLabel(selWave, 2, "WS_InfoPlane") < 0)
		Variable selPlanes = DimSize(selWave, 2)
		selPlanes = selPlanes == 0 ? 2 : selPlanes+1
		Redimension/N=(-1, -1, selPlanes) selWave
		SetDimLabel 2, selPlanes-1, WS_InfoPlane, selWave
		selWave[][][selPlanes-1] = -1		// indicates not a popup cell; will be changed later to contain options for that cell
	endif
	
	if (FindDimLabel(listWave, 2, "WS_PathPlane") < 0)
		Variable listPlanes = DimSize(listWave, 2)
		listPlanes = listPlanes == 0 ? 2 : listPlanes+1
		Redimension/N=(-1, -1, listPlanes) listWave
		SetDimLabel 2, listPlanes-1, WS_PathPlane, listWave
	endif
	
	if (row >= DimSize(selWave, 0))
		return PopupWS_ErrorSelWaveBadRows
	endif
	if (column >= DimSize(selWave, 1))
		return PopupWS_ErrorSelWaveBadColumns
	endif
	if (row >= DimSize(listWave, 0))
		return PopupWS_ErrorListWaveBadRows
	endif
	if (column >= DimSize(listWave, 1))
		return PopupWS_ErrorListWaveBadColumns
	endif
	
	listbox $hostListbox, win=$hostWindow,userData(popupWSInfo)=infoStr,proc=PopupWaveSelectorListboxProc
	listbox $hostListbox, win=$hostWindow,userData(popupWSListBoxProc)=listboxproc
	listWave[row][column][0] = listWave[row][column] + RightJustString + Font9String + MenuArrowString
	listWave[row][column][%WS_PathPlane] = ""
	selWave[row][column][%WS_InfoPlane] = options
	
	Wave/Z w=$initialSelection
	Variable isWave= WaveExists(w)
	Variable isDataFolder= DataFolderExists(initialSelection+":")	
	String str
	
	if (!TitleInTitle)
		if (isWave)
			str= NameOfWave(w)
		elseif(isDataFolder)
			str= initialSelection
		else
			str= NoSelectionString
		endif
		listWave[row][column][0] = str+RightJustString+Font9String+MenuArrowString
	endif
	if (isWave)
		str= GetWavesDataFolder(w, 2)
	elseif(isDataFolder)
		str= initialSelection
	else
		str= NoSelectionString
	endif
	PopupWS_SetSelectionFullPath(hostWindow, hostListbox, str, row=row, column=column)
	SetWindow $(StringFromList(0, hostWindow, "#")), hook(PopupWS_HostWindowHook)=PopupWSHostHook		// for the rename event

	return PopupWS_ErrorNoError
end

Function/S PopupWS_GetSelectionFullPath(hostWindow, ctrlName [, row, column])
	string hostWindow, ctrlName
	Variable row, column

	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, ctrlName, popInfo))
		return ""
	endif

	ControlInfo/W=$hostWindow $ctrlName
	Variable ctrlType = V_flag
	if (ctrlType == 11)					// listbox
		Wave/T listWave = $(S_DataFolder + S_value)
		String pathPlaneStr = listwave[row][column][%WS_PathPlane]
		String fullpath = StringByKey("FULLPATH", pathPlaneStr, "=", "\r")
	else
		fullpath = GetUserData(hostWindow, ctrlName, "PopupWS_FullPath")
	endif
	
	return fullpath
end

// return 0 if all is well, -1 if there's no popInfo struct created yet
Function PopupWS_SetPopupFont(hostWindow, ctrlName, [fontSize, fontStyle])
	String hostWindow, ctrlName
	Variable fontSize, fontStyle
	
	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, ctrlName, popInfo))
		return -1
	endif
	
	/// determine if the popup exists
	DoWindow/F popupWSPanel
	Variable popupExists = V_flag /// may be any non-0
	
	if (!ParamIsDefault(fontSize))
		popInfo.fontSize = fontSize
		if (popupExists && fontSize > 0)
			ListBox list0,win=popupWSPanel, fsize=popInfo.fontSize
		endif		
	endif
	if (!ParamIsDefault(fontStyle))
		popInfo.fontStyle = fontStyle
		if (popupExists && fontStyle > 0)
			ListBox list0,win=popupWSPanel, fStyle=popInfo.fontStyle
		endif
	endif
	
	String infoStr
	StructPut/S popInfo, infoStr
	
	if (strlen(popInfo.hostSetVar) > 0)
		SetVariable $(popInfo.hostSetVar), win=$hostWindow, userData(popupWSInfo)=infoStr
	endif
//	Button $(popInfo.hostButton), win=$hostWindow, userData(popupWSInfo)=infoStr
	ModifyControl $popInfo.hostButton, win=$hostWindow,userdata(popupWSInfo)=infoStr	

	return 0
End

Function PopupWS_SetSelectionFullPath(hostWindow, ctrlName, fullPath [, row, column])
	string hostWindow, ctrlName
	Variable row, column
	String fullPath

	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, ctrlName, popInfo))
		return -1
	endif

	Wave/Z w = $fullPath
	ControlInfo/W=$hostWindow $ctrlName
	Variable ctrlType = V_flag
	if (ctrlType == 11)					// listbox
		Wave/T listWave = $(S_DataFolder + S_value)
		String pathPlaneStr = listwave[row][column][%WS_PathPlane]
		pathPlaneStr = ReplaceStringByKey("FULLPATH", pathPlaneStr, fullPath, "=", "\r")
		listwave[row][column][%WS_PathPlane] = pathPlaneStr
		String SelectableStrings = StringByKey("SELECTABLESTRINGS", pathPlaneStr, "=", "\r")
		if ( (popInfo.options & PopupWS_OptionTitleInTitle) == 0)
			if (WaveExists(w))
				listwave[row][column][0] = RightJustString+NameOfWave(w)+" "+MenuArrowString
			else
				listwave[row][column][0] = RightJustString+fullPath+" "+MenuArrowString
			endif
		endif
	else
		ModifyControl $popInfo.hostButton, win=$popInfo.hostWindow,userdata(PopupWS_FullPath)=fullPath
		if (strlen(popInfo.hostSetVar) > 0)
			ModifyControl $popInfo.hostSetVar, win=$popInfo.hostWindow,userdata(PopupWS_FullPath)=fullPath
			String globalString = GetUserData(popInfo.hostWindow, popInfo.hostButton, "popupWSGString")
			SVAR theString = $globalString
			if (WaveExists(w))
				theString = NameOfWave(w)
			else
				theString = fullPath
			endif
		else
			if ( (popInfo.options & PopupWS_OptionTitleInTitle) == 0)
				if (WaveExists(w))
					ModifyControl $popInfo.hostButton, win=$popInfo.hostWindow,title=RightJustString+NameOfWave(w)+" "+MenuArrowString
				else
					ModifyControl $popInfo.hostButton, win=$popInfo.hostWindow,title=RightJustString+fullPath+" "+MenuArrowString
				endif
			endif
		endif
	endif
	
	return 0
end

Function PopupWS_AddSelectableString(hostWindow, ctrlName, theString [, row, column])
	string hostWindow, ctrlName
	String theString
	Variable row, column
	
	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, ctrlName, popInfo))
		return 0
	endif

	ControlInfo/W=$hostWindow $ctrlName
	Variable ctrlType = V_flag
	if (ctrlType == 11)					// listbox
		Wave/T listWave = $(S_DataFolder + S_value)
		String pathPlaneStr = listwave[row][column][%WS_PathPlane]
		String SelectableStrings = StringByKey("SELECTABLESTRINGS", pathPlaneStr, "=", "\r")
		SelectableStrings += theString+";"
		pathPlaneStr = ReplaceStringByKey("SELECTABLESTRINGS", pathPlaneStr, SelectableStrings, "=", "\r")
		listwave[row][column][%WS_PathPlane] = pathPlaneStr
	else
		SelectableStrings = GetUserData(hostWindow, ctrlName, "PopupWS_SelectableStrings" )
		SelectableStrings += theString+";"
		ModifyControl $ctrlName, win=$hostWindow, userdata(PopupWS_SelectableStrings) = SelectableStrings
		if (abs(ctrlType) == 5)
			ModifyControl $popInfo.hostButton, win=$hostWindow, userdata(PopupWS_SelectableStrings) = SelectableStrings
		endif
	endif
end	

Function PopupWS_RemoveSelectableString(hostWindow, ctrlName, theString [, row, column])
	string hostWindow, ctrlName
	String theString
	Variable row, column
	
	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, ctrlName, popInfo))
		return 0
	endif

	ControlInfo/W=$hostWindow $ctrlName
	Variable ctrlType = V_flag
	if (ctrlType == 11)					// listbox
		ControlInfo/W=$hostWindow $ctrlName
		Wave/T listWave = $(S_DataFolder + S_value)
		String pathPlaneStr = listwave[row][column][%WS_PathPlane]
		String SelectableStrings = StringByKey("SELECTABLESTRINGS", pathPlaneStr, "=", "\r")
		SelectableStrings = RemoveFromList(theString, SelectableStrings)
		pathPlaneStr = ReplaceStringByKey("SELECTABLESTRINGS", pathPlaneStr, SelectableStrings, "=", "\r")
		listwave[row][column][%WS_PathPlane] = pathPlaneStr
	else
		SelectableStrings = GetUserData(hostWindow, ctrlName, "PopupWS_SelectableStrings" )
		SelectableStrings = RemoveFromList(theString, SelectableStrings)
		ModifyControl $ctrlName, win=$hostWindow, userdata(PopupWS_SelectableStrings) = SelectableStrings
		if (abs(ctrlType) == 5)
			ModifyControl $popInfo.hostButton, win=$hostWindow, userdata(PopupWS_SelectableStrings) = SelectableStrings
		endif
	endif
end	

Function PopupWS_Move(hostWindow, ctrlName, newleft, newtop)
	string hostWindow, ctrlName
	Variable newtop, newleft
	
	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, ctrlName, popInfo))
		return 0
	endif

	ControlInfo/W=$hostWindow $ctrlName

	Variable oldLeft = V_left
	Variable oldTop = V_top
	Variable deltaX = oldLeft - newleft
	Variable deltaY = oldTop - newtop
		
	if (strlen(popInfo.hostSetVar) > 0)
		ControlInfo/W=$popInfo.hostWindow $popInfo.hostSetVar
		Variable ctrlLeft = V_left-deltaX
		Variable ctrlTop = V_top-deltaY
		ModifyControl $popInfo.hostSetVar,win=$popInfo.hostWindow, pos={ctrlLeft, ctrlTop}

		String gboxName = GetUserData(popInfo.hostWindow, popInfo.hostSetVar, "PopupWS_FrameName")
		if (strlen(gboxName) > 0)
			ControlInfo/W=$popInfo.hostWindow $gboxName
			ctrlLeft = V_left-deltaX
			ctrlTop = V_top-deltaY
			ModifyControl $gboxName,win=$popInfo.hostWindow, pos={ctrlLeft, ctrlTop}
		endif
		
//		bName = GetUserData(popInfo.hostWindow, popInfo.hostSetVar, "PopupWS_ButtonName")
		ControlInfo/W=$popInfo.hostWindow $popInfo.hostButton
		ctrlLeft = V_left-deltaX
		ctrlTop = V_top-deltaY
		ModifyControl $popInfo.hostButton,win=$popInfo.hostWindow, pos={ctrlLeft, ctrlTop}
	else
		ModifyControl $ctrlName,win=$hostWindow, pos={newleft, newtop}
	endif
end

Function PopupWS_Resize(hostWindow, ctrlName, newWidth, newHeight)
	string hostWindow, ctrlName
	Variable newWidth, newHeight

	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, ctrlName, popInfo))
		return 0
	endif
	
	if (strlen(popInfo.hostSetVar) > 0)
		ControlInfo/W=$popInfo.hostWindow $popInfo.hostSetVar
		Variable bodyWidthPos = StrSearch(S_recreation, "bodyWidth=", 0)
		if (bodyWidthPos >= 0)
			SetVariable $popInfo.hostSetVar,win=$popInfo.hostWindow,size={V_width, newHeight},bodywidth=(newWidth)
		else
			ModifyControl $popInfo.hostSetVar,win=$popInfo.hostWindow, size={newWidth, newHeight}
		endif
		ControlUpdate/W=$popInfo.hostWindow $popInfo.hostSetVar
		
		STRUCT SVdimensions svd
		Variable lineFrame = (popInfo.options&PopupWS_OptionSVLineFrame)!=0
		PopupWS_SVcalcDimensions(popInfo.hostWindow, popInfo.hostSetVar, lineFrame, svd)

		String gboxName = GetUserData(popInfo.hostWindow, popInfo.hostSetVar, "PopupWS_FrameName")
		if (strlen(gboxName) > 0)
			ModifyControl $gboxName,win=$popInfo.hostWindow, pos={svd.gbleft, svd.gbtop},size={svd.gbWidth, svd.gbHeight}
		endif
		
//		bName = GetUserData(popInfo.hostWindow, popInfo.hostSetVar, "PopupWS_ButtonName")
		ModifyControl $popInfo.hostButton,win=$popInfo.hostWindow, pos={svd.buttonleft, svd.buttontop},size={svd.buttonwidth, svd.buttonheight}
	else
		ModifyControl $ctrlName,win=$hostWindow, size={newWidth, newHeight}
	endif
end

Function PopupWS_MatchOptions(hostWindow, ctrlName [,row, column, matchStr, listoptions, nameFilterProc])
	string hostWindow, ctrlName
	Variable row, column
	String matchStr, listoptions, nameFilterProc

	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, ctrlName, popInfo))
		return 0
	endif
	
	if (!ParamIsDefault(listoptions))
		if (strlen(listoptions) > 200)
			return PopupWS_ErrorStringTooLong
		endif
	endif

	ControlInfo/W=$hostWindow $ctrlName
	if (V_flag == 11)
		Wave/T listWave = $(S_DataFolder + S_value)
		String PathPlaneStr = listwave[row][column][%WS_PathPlane]
		if (!ParamIsDefault(matchStr))
			pathPlaneStr = ReplaceStringByKey("MATCHSTR", pathPlaneStr, matchStr, "=", "\r")
		endif
		if (!ParamIsDefault(listoptions))
			pathPlaneStr = ReplaceStringByKey("LISTOPTIONS", pathPlaneStr, listoptions, "=", "\r")
		endif
		if (!ParamIsDefault(nameFilterProc))
			pathPlaneStr = ReplaceStringByKey("FILTERPROC", pathPlaneStr, nameFilterProc, "=", "\r")
		endif
		listwave[row][column][%WS_PathPlane] = pathPlaneStr
	else
		if (!ParamIsDefault(matchStr))
			ModifyControl $popInfo.hostButton,win=$hostWindow,userdata(PopupWS_MatchStr)=(matchStr)
		endif
		if (!ParamIsDefault(listoptions))
			ModifyControl $popInfo.hostButton,win=$hostWindow,userdata(PopupWS_ListOptions)=(listoptions)
		endif
		if (!ParamIsDefault(nameFilterProc))
			ModifyControl $popInfo.hostButton,win=$hostWindow,userdata(PopupWS_filterProc)=(nameFilterProc)
		endif
	endif
end

Function PopupWS_SetGetSortOrder(windowname, listcontrolname, sortKindOrMinus1, sortReverseOrMinus1)
	String windowname, listcontrolname	// windowname, listcontrolname can also be popupcontrolwindow, popupcontrolname passed into MakePopupIntoWaveSelectorSort
	Variable &sortKindOrMinus1		// -1 means don't change sortKind AND return the current sortKind
	Variable &sortReverseOrMinus1	// -1 means don't change sortReverse AND return the current sortReverse

	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(windowname, listcontrolname, popInfo))
		return 0
	endif
	
	Variable WriteBack = 0

	if (sortKindOrMinus1 == -1)
		sortKindOrMinus1 = popInfo.SortKind
	else
		popInfo.SortKind = sortKindOrMinus1
		WriteBack = 1
	endif
	
	if (sortReverseOrMinus1 == -1)
		sortReverseOrMinus1 = popInfo.SortOrder
	else
		popInfo.SortOrder = sortReverseOrMinus1
		WriteBack = 1
	endif
	
	if (WriteBack)
		PopupWSPutStruct(popInfo)
	endif
end

static Function popupWSGetMatchOptions(hostWindow, ctrlName, matchStr, listoptions, nameFilterProc [, row, column])
	String hostWindow, ctrlName
	String &matchStr, &listoptions, &nameFilterProc
	Variable row, column

	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, ctrlName, popInfo))
		return 0
	endif
	
	ControlInfo/W=$hostWindow $ctrlName
	if (V_flag == 11)
		Wave/T listWave = $(S_DataFolder + S_value)
		String PathPlaneStr = listwave[row][column][%WS_PathPlane]
		matchStr = StringByKey("MATCHSTR", pathPlaneStr, "=", "\r")
		listoptions = StringByKey("LISTOPTIONS", pathPlaneStr, "=", "\r")
		nameFilterProc = StringByKey("FILTERPROC", pathPlaneStr, "=", "\r")
	else
		matchStr = GetUserData(hostWindow, popInfo.hostButton, "PopupWS_MatchStr")
		listoptions = GetUserData(hostWindow, popInfo.hostButton, "PopupWS_ListOptions")
		nameFilterProc = GetUserData(hostWindow, popInfo.hostButton, "PopupWS_filterProc")
	endif
end

#if Exists("PanelResolution") != 3
Static Function PanelResolution(wName)			// For compatibility with Igor 7
	String wName
	return 72
End
#endif


static Function fpopupWSPanel(leftInPoints, topInPoints, hostWindow, hostButton [, row, column, selectableStringList])
	Variable leftInPoints, topInPoints
	String hostWindow, hostButton
	Variable row, column
	String selectableStringList

	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, hostButton, popInfo))
		return 0
	endif
	
	String matchStr
	String listoptions
	String nameFilterProc
	popupWSGetMatchOptions(hostWindow, popInfo.hostButton, matchStr, listoptions, nameFilterProc, row=row, column=column)
	if (strlen(matchStr) == 0)
		matchStr = "*"
	endif
	
	Variable factor = PanelResolution(hostWindow)/ScreenResolution
	
	if (WinType("popupWSPanel") == 7)
		// This can happen, for instance, if the user clicks on the popup button when the popup panel is already up. That case should be
		// treated simply as a click outside the popup panel window, so here we simply kill the window without selecting.
		KillWindow popupWSPanel
		return 0
	endif

	NewPanel /FLT=(popInfo.doFloat)/K=1 /W=(leftInPoints/factor,topInPoints/factor,leftInPoints/factor+popInfo.width,topInPoints/factor+popInfo.height) as ""
	RenameWindow $S_name, popupWSPanel
	ModifyPanel fixedSize=0, noEdit=1
	DefaultGUIFont/W=popupWSPanel popup={"_IgorSmall", 9, 0 }
	GetWindow popupWSPanel,wsizeOuter
	MoveWindow/W=popupWSPanel 2*leftInPoints-V_left, 2*topInPoints-V_top, (2*leftInPoints-V_left)+popInfo.width*factor, 2*topInPoints-V_top+popInfo.height*factor

	ListBox list0,win=popupWSPanel,pos={0, 0},size={popInfo.width, popInfo.height-kPopMenuMargin}
	MakeListIntoWaveSelector("popupWSPanel", "list0", selectionMode=WMWS_SelectionSingle, listoptions=listoptions, matchStr=matchStr, nameFilterProc=nameFilterProc, content=popInfo.content)
	PopupWS_SetPopupFont(hostWindow, hostButton, fontSize=popInfo.fontSize, fontStyle=popInfo.fontStyle)
	WS_SetNotificationProc("popupWSPanel", "list0", "waveSelectedNotifyProc", isExtendedProc=1)
	PopupWSPutStruct(popInfo)
	PopupMenu PopupWS_OptionsMenu,pos={1, popInfo.height-kPopMenuHeight-2},size={71,kPopMenuHeight}
	MakePopupIntoWaveSelectorSort("popupWSPanel", "list0", "PopupWS_OptionsMenu")
	Variable sortKind = popInfo.SortKind
	Variable sortOrder = popInfo.SortOrder
	WS_SetGetSortOrder("popupWSPanel", "PopupWS_OptionsMenu", sortKind, sortOrder)
	
	Variable i
	Variable items = ItemsInList(selectableStringList)
	for (i = 0; i < items; i += 1)
		WS_AddSelectableString("popupWSPanel", "list0", StringFromList(i, selectableStringList))
	endfor
	
	SetWindow popupWSPanel, hook(popupWSPanelHookProc)=popupWSPanelHook
	SetWindow popupWSPanel, userData(popupWSHostWindow) = hostWindow
	SetWindow popupWSPanel, userData(popupWSHostButton) = hostButton	
	String infoString
	StructPut/S popInfo, infoString
	SetWindow popupWSPanel, userData(popupWSInfo) = infoString
	if (!ParamIsDefault(row))
		SetWindow popupWSPanel, userData(popupWSrow) = num2str(row)
		SetWindow popupWSPanel, userData(popupWScol) = num2str(column)
	endif
		
	string initialSelection = GetUserData(hostWindow, hostButton, "PopupWS_FullPath")
	WS_OpenAFolderFully("popupWSPanel", "list0", GetDataFolder(1))
	WS_SelectAnObject("popupWSPanel", "list0", initialSelection, OpenFoldersAsNeeded=1)
	if (popInfo.doFloat)
		SetActiveSubwindow _endfloat_
	endif
EndMacro

Function popupWS_ButtonNotifyTemplate(event, wavepath, windowName, buttonName)
	Variable event
	String wavepath
	String windowName
	String buttonName
	
end

Function popupWS_ListboxNotifyTemplate(event, wavepath, windowName, buttonName, row, column)
	Variable event
	String wavepath
	String windowName
	String buttonName
	Variable row, column
	
end

Function waveSelectedNotifyProc(SelectedItem, EventCode, OwningWindowName, ListboxControlName)
	String SelectedItem			// string with full path to the item clicked on in the wave selector
	Variable EventCode			// the ListBox event code that triggered this notification
	String OwningWindowName	// String containing the name of the window containing the listbox
	String ListboxControlName	// String containing the name of the listbox control

	if (EventCode == WMWS_SelectionChanged)	
		String infoString = GetUserData(	OwningWindowName, "", "popupWSInfo")
		STRUCT PopupWaveSelectorInfo popInfo
		StructGet/S popInfo, infoString
		if (popInfo.version == 0)
			return 0
		endif

		Wave/Z w=$SelectedItem
		Variable isWave= WaveExists(w)
		Variable isDataFolder= DataFolderExists(selectedItem+":")
		String fullPath=""
		if (isWave)
			fullPath = GetWavesDataFolder(w, 2)
		elseif (isDataFolder)
			fullPath= selectedItem
		endif
		
		// These are placed here so that they get into the Operation Queue ahead of anything the user's notification function might put there.
		// This was inspired by Andy Nelson, who makes a wave and wants it to become the selection. He makes the wave inside the
		// notification function. I'm about to tell him that he should use Execute/P to call PopupWS_SetSelectionFullPath().
		Execute/P/Q/Z "DoWindow/W=popupWSPanel/K popupWSPanel"
		Execute/P/Q/Z "ControlUpdate/W="+popInfo.hostWindow+" "+popInfo.hostButton
		
		ControlInfo/W=$popInfo.hostWindow $popInfo.hostButton
		if (V_flag == 1)						// it really is a button
//			Button $popInfo.hostButton win=$popInfo.hostWindow, userData(PopupWS_FullPath)=SelectedItem
			string SelectableStrings = GetUserData(popInfo.hostWindow, popInfo.hostButton, "PopupWS_SelectableStrings")

			String help=""
			if (isWave || isDataFolder)
				help = fullPath
			elseif (FindListItem(SelectedItem, SelectableStrings) >= 0)
				fullPath = SelectedItem
			endif
			if (strlen(help) > 0)
				Button $popInfo.hostButton win=$popInfo.hostWindow, help={help}
				if (strlen(popInfo.hostSetVar) > 0)
					SetVariable $popInfo.hostSetVar, win=$popInfo.hostWindow, help={help}
				endif
			endif
			
			if ( (popInfo.options & PopupWS_OptionTitleInTitle) == 0 )
				if (isWave)
					Button $popInfo.hostButton win=$popInfo.hostWindow,title=RightJustString+NameOfWave(w)+" "+MenuArrowString
				elseif (isDataFolder || (FindListItem(SelectedItem, SelectableStrings) >= 0))
					Button $popInfo.hostButton win=$popInfo.hostWindow,title=RightJustString+SelectedItem+" "+MenuArrowString
//				else
	//				Button $popInfo.hostButton win=$popInfo.hostWindow,title=RightJustString+NoSelectionString+" "+MenuArrowString
				endif
			endif
			
			ModifyControl $popInfo.hostButton, win=$popInfo.hostWindow,userdata(PopupWS_FullPath)=fullPath
			if (strlen(popInfo.hostSetVar) > 0)
				ModifyControl $popInfo.hostSetVar, win=$popInfo.hostWindow,userdata(PopupWS_FullPath)=fullPath
			endif
			
			FUNCREF popupWS_ButtonNotifyTemplate buttonfunc = $popInfo.NotificationProc
			String ctrlName = popInfo.hostButton
			if (strlen(popInfo.hostSetVar) > 0)
				ctrlName = popInfo.hostSetVar
			endif
			buttonfunc(WMWS_SelectionChanged, StringFromList(0, WS_SelectedObjectsList("popupWSPanel", "list0")), popInfo.hostWindow, ctrlName)
			
		elseif (V_flag == 11)				// it's a listbox
		
			Wave/T listWave = $(S_DataFolder + S_value)
			S_recreation = replacestring("\r", S_recreation, ",")
			Wave selWave = $(StringByKey("selWave", S_recreation, "=", ","))
			Variable row = str2num(GetUserData(OwningWindowName, "", "popupWSrow"))
			Variable col = str2num(GetUserData(OwningWindowName, "", "popupWScol"))
			Variable options = selWave[row][col][%WS_InfoPlane]
			
			String pathPlaneStr = listwave[row][col][%WS_PathPlane]
			SelectableStrings = StringByKey("SELECTABLESTRINGS", pathPlaneStr, "=", "\r")

			if ( (options & PopupWS_OptionTitleInTitle) == 0 )
				if (WaveExists(w))
					listwave[row][col][0] = NameOfWave(w)+RightJustString+Font9String+MenuArrowString
				elseif (FindListItem(SelectedItem, SelectableStrings) >= 0)
					listwave[row][col][0] = SelectedItem+RightJustString+Font9String+MenuArrowString
//				else
//					listwave[row][col][0] = NoSelectionString+RightJustString+Font9String+MenuArrowString
				endif
			endif
			
			pathPlaneStr = ReplaceStringByKey("FULLPATH", pathPlaneStr, SelectedItem, "=", "\r")
			listwave[row][col][%WS_PathPlane] = pathPlaneStr
			
			
			FUNCREF popupWS_ListboxNotifyTemplate lbfunc = $popInfo.NotificationProc
			ctrlName = popInfo.hostButton
			lbfunc(WMWS_SelectionChanged, StringFromList(0, WS_SelectedObjectsList("popupWSPanel", "list0")), popInfo.hostWindow, ctrlName, row, col)
			
		endif

		String globalString = GetUserData(popInfo.hostWindow, popInfo.hostButton, "popupWSGString")
		SVAR/Z gs = $globalString
		if (SVAR_Exists(gs))
			if (isWave)
				gs = NameOfWave(w)
			elseif (isDataFolder || FindListItem(SelectedItem, SelectableStrings) >= 0)
				gs = SelectedItem
//			else
	//			gs = NoSelectionString
			endif
		endif
		
		ControlUpdate/W=$popInfo.hostWindow $popInfo.hostButton
	endif
end

Function PopupWaveSelectorPop(hostWindow, hostButton)
	String hostWindow, hostButton
	
	STRUCT PopupWaveSelectorInfo popInfo
	if (PopupWSGetStruct(hostWindow, hostButton, popInfo))
		return 0
	endif

	Variable leftInPixels, topInPixels, bottomInPixels, rightInPixels
	String ctrl = SelectString(strlen(popInfo.hostSetVar) > 0, hostButton, popInfo.hostSetVar)
	GlobalCtrlCoordsInPixels(hostWindow, ctrl, leftInPixels, topInPixels, rightInPixels, bottomInPixels, popInfo.doFloat)
	
	String selectableStrings = GetUserData(hostWindow, hostButton, "PopupWS_SelectableStrings")
	fpopupWSPanel(leftInPixels*PanelResolution(hostWindow)/ScreenResolution, bottomInPixels*PanelResolution(hostWindow)/ScreenResolution, hostWindow, hostButton, selectableStringList=selectableStrings)
end

Function GlobalCtrlCoordsInPixels(hostWindow, ctrlName, left, top, right, bottom, floats)
	String hostWindow, ctrlName
	Variable &left, &top, &right, &bottom
	Variable floats
	
#if NumberByKey("IGORVERS", IgorInfo(0)) >= 6.04
	if (floats)
		ControlInfo/W=$hostWindow/G $ctrlName
		top = V_top
		left = V_left
		right = left+V_width
		bottom = top+V_height
	else
		ControlInfo/W=$hostWindow $ctrlName
		top = V_top
		left = V_left
		right = left+V_width
		bottom = top+V_height
		GetWindow $hostWindow, wsize
		Variable factor = screenResolution/PanelResolution(hostWindow)
		left += V_left*factor
		right += V_left*factor
		top += V_top*factor
		bottom += V_top*factor
	endif
#else
	ControlInfo/W=$hostWindow $ctrlName
	top = V_top
	left = V_left
	right = left+V_width
	bottom = top+V_height
	do
		GetWindow $hostWindow, wsize
		top += V_top*screenResolution/PanelResolution(hostWindow)
		left += V_left*screenResolution/PanelResolution(hostWindow)
		right += V_left*screenResolution/PanelResolution(hostWindow)
		bottom += V_top*screenResolution/PanelResolution(hostWindow)
		string topWindow = ParseFilePath(0, hostWindow,"#", 0, 0)
		if (CmpStr(topWindow, hostWindow) == 0)
			break;
		endif
		GetWindow $topWindow, wsize
		top += V_top*screenResolution/PanelResolution(hostWindow)
		left += V_left*screenResolution/PanelResolution(hostWindow)
		right += V_left*screenResolution/PanelResolution(hostWindow)
		bottom += V_top*screenResolution/PanelResolution(hostWindow)
		hostWindow = ParseFilePath(0, hostWindow,"#", 0, 0)
	while(0) 	
#endif	
	return 0
end

Function PopupWaveSelectorButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
//		case 2: // mouse up
		case 1: // mouse down
			PopupWaveSelectorPop(ba.win, ba.ctrlName)
			break;
	endswitch

	return 0
End

Function PopupWSSetVarProc(sv) : SetVariableControl
	STRUCT WMSetVariableAction &sv
	
	switch (sv.eventCode)
		case -1:						// control being killed
			String cname = GetUserData(sv.win, sv.ctrlName, "PopupWS_ButtonName")
			KillControl/W=$sv.win $cname
			cname = GetUserData(sv.win, sv.ctrlName, "PopupWS_FrameName")
			KillControl/W=$sv.win $cname
			String setVarList = GetUserData(sv.win, "", "PopupWS_SetVarList")
			setVarList = RemoveFromList(sv.ctrlName, setVarList)
			SetWindow $sv.win, userData(PopupWS_SetVarList)=setVarList
			break;
	endswitch
end

Function ListboxProcTemplate(lb)
	STRUCT WMListboxAction &lb
end

Function PopupWaveSelectorListboxProc(lb) : ListboxControl
	STRUCT WMListboxAction &lb
	
	Variable result=0

	switch (lb.eventCode)
		case 1:
			Variable listPathPlane = FindDimLabel(lb.listWave, 2, "WS_PathPlane")
			if (listPathPlane < 0)
				break;
			endif
			Variable selInfoPlane = FindDimLabel(lb.selWave, 2, "WS_InfoPlane")
			if (selInfoPlane < 0)
				break;
			endif
			if (lb.row >= DimSize(lb.selWave, 0))
				break;
			endif
			if (lb.row < 0)
				break;
			endif
			if (lb.col >= DimSize(lb.selWave, 1))
				break;
			endif
			if (lb.col < 0)
				break;
			endif
			if (lb.selWave[lb.row][lb.col][selInfoPlane] < 0)
				break;
			endif
			
			String pathString = lb.listwave[lb.row][lb.col][listPathPlane]

			ModifyControl $lb.ctrlName,win=$lb.win,userdata(PopupWS_FullPath)=StringByKey("FULLPATH", pathString, "=", "\r")
			
			Variable i
			Variable numCols = DimSize(lb.listWave, 1)
			Variable hasTitles = 0
			for (i = 0; i < numCols; i += 1)
				if (strlen(GetDimLabel(lb.listWave, 1, i )) > 0)
					hasTitles = 1
					break;
				endif
			endfor
			
			STRUCT PopupWaveSelectorInfo popInfo
			if (PopupWSGetStruct(lb.win, lb.ctrlName, popInfo))
				return 0
			endif
			Variable leftInPixels, topInPixels, rightInPixels, bottomInPixels
			GlobalCtrlCoordsInPixels(lb.win, lb.ctrlName, leftInPixels, topInPixels, rightInPixels, bottomInPixels, popInfo.doFloat)

			ControlInfo/W=$lb.win $lb.ctrlName
			topInPixels += (lb.row-V_startRow+1+hasTitles)*V_rowHeight
			for (i = 0; i < lb.col; i += 1)
				leftInPixels += str2num(StringFromList(i, S_columnWidths, ","))
			endfor
			
			String SelectableStrings = StringByKey("SELECTABLESTRINGS", pathString, "=", "\r")
			fpopupWSPanel(leftInPixels*PanelResolution(lb.win)/ScreenResolution, topInPixels*PanelResolution(lb.win)/ScreenResolution, lb.win, lb.ctrlName, row=lb.row, column=lb.col, selectableStringList=selectableStrings)
			result = 1
			break;
	endswitch
	
	if (!result)
		String userproc = GetUserData(lb.win, lb.ctrlName, "popupWSListBoxProc")
		if (strlen(userproc) > 0)
			FUNCREF ListboxProcTemplate theProc = $userproc
			result = theProc(lb)
		endif
	endif
	return result
End

// the hook function installed on the popup panel. That is, the window that appears when you click on a popup button, setvariable, or list cell.
Function popupWSPanelHook(ws)
	STRUCT WMWinHookStruct &ws

	switch(ws.eventCode)
		case 1:							// deactivate
			Execute/P/Q/Z "DoWindow/W=popupWSPanel/K popupWSPanel"
			break;
		case 2:							// kill
			string infoString = GetUserData(ws.winname, "", "popupWSInfo")
			STRUCT PopupWaveSelectorInfo popInfo
			StructGet/S popInfo, infoString
			if (popInfo.version == 0)
				return 0
			endif

			String hostWindow = GetUserData(ws.winname, "", "popupWSHostWindow")
			String hostButton = GetUserData(ws.winname, "", "popupWSHostButton")
			popInfo.width = ws.winRect.right - ws.winRect.left
			popInfo.height = ws.winRect.bottom - ws.winRect.top
			
			Variable sortKind=-1
			Variable sortOrder=-1
			WS_SetGetSortOrder(ws.winName, "PopupWS_OptionsMenu", sortKind, sortOrder)
			popInfo.SortKind = sortKind
			popInfo.SortOrder = sortOrder

			PopupWSPutStruct(popInfo)
			break;
		case 11:
			switch(ws.keycode)
				case 27:				// escape
				case 3:					// enter key on keypad (at least on Macintosh)
				case 13:				// return
					Execute/P/Q/Z "DoWindow/W=popupWSPanel/K popupWSPanel"
					break;
				default:
					//print ws.keycode
					break;
			endswitch
			break;
		case 6:							// resize
			Variable height = ws.winRect.bottom - ws.winRect.top
			PopupMenu PopupWS_OptionsMenu,win=$ws.winName,pos={1, height-kPopMenuHeight-2}
			ListBox list0,win=$ws.winName,size={ws.winRect.right - ws.winRect.left, height-kPopMenuMargin}
			break;
	endswitch

	return 0		// 0 if nothing done, else 1
End

static Function within(num, low, high)
	Variable num, low, high
	
	return (num >= low) && (num <= high)
end

static Function ptInRect(pHoriz, pVert, rLeft, rTop, rRight, rBottom)
	Variable pHoriz, pVert, rLeft, rTop, rRight, rBottom

	return within(pVert, rTop, rBottom) && within(pHoriz, rLeft, rRight)
end

Function PopupWSHostHook(s)
	STRUCT WMWinHookStruct &s

	Variable rval= 0
	strswitch(s.eventName)
		case "mousedown":						// mousedown
			String setVarList = GetUserData(s.winName, "", "PopupWS_SetVarList")
			Variable items = ItemsInList(setVarList)
			Variable i
			for (i = 0; i < items; i += 1)
				String setVarName = StringFromList(i, setVarList)
				ControlInfo/W=$s.winName $setVarName
				if (abs(V_flag) == 5 && V_disable == 0)
					if (ptInRect(s.mouseLoc.h, s.mouseLoc.v, V_left, V_top, V_left+V_width, V_top + V_height))
						String hostButton = GetUserData(s.winName, setVarName, "PopupWS_ButtonName")
						PopupWaveSelectorPop(s.winName, hostButton)
						
						// returning 1 tells Igor that we handled the mousedown. If we return 0, the mousedown goes through
						// and causes the host panel to activate, which de-activates the new popup panel, the window hook
						// for the popup panel runs, and kills the popup panel too soon.
						rval = 1
						break;			// just in case we have overlapping controls, or the control is entered more than once in the list
					endif
				endif
			endfor
			break;
		case "renamed":
			PopupWSHandleWinRenamed(s.oldWinName, s.winName)
			break;
	endswitch
	
	return rval
end

static Function PopupWSHandleWinRenamed(oldName, newName)
	String oldName, newName

	String ChildList = ChildWindowList(newName)
	Variable items = ItemsInList(ChildList)
	Variable i
	if (items > 0)
		for (i = 0; i < items; i += 1)
			String oneChild = StringFromList(i, ChildList)
			PopupWSHandleWinRenamed(oldName+"#"+oneChild, newName+"#"+oneChild)
		endfor
	endif
	
	String controlList = ControlNameList(newName)
	items = ItemsInList(controlList)
	for (i = 0; i < items; i += 1)
		String ctrlName = StringFromList(i, controlList)
		STRUCT PopupWaveSelectorInfo popInfo
		if (PopupWSGetStruct(newName, ctrlName, popInfo) == 0)
			popInfo.hostWindow = newName
			PopupWSPutStruct(popInfo)
		endif
	endfor
end

static Function PopupWSGetStruct(hostWindow, hostButton, popInfo)
	String hostWindow, hostButton
	STRUCT PopupWaveSelectorInfo &popInfo
	
	ControlInfo/W=$hostWindow $hostButton
	if (V_flag == 0)
		return -1
	endif
		
	string infoString = GetUserData(hostWindow, hostButton, "popupWSInfo")
	if (strlen(infoString) == 0)
		popInfo.version = 0
		return -1
	else
		StructGet/S popInfo, infoString
		if( popInfo.content == 0 )
			popInfo.content= WMWS_Waves	// backwards compatibility with version 1.0 popInfo's
		endif
		return 0
	endif
end

static Function PopupWSPutStruct(popInfo)
	STRUCT PopupWaveSelectorInfo &popInfo
	
	
	string infoString
	StructPut/S popInfo, infoString
	ModifyControl $popInfo.hostButton,win=$popInfo.hostWindow,userData(popupWSInfo)=infoString
	if (strlen(popInfo.hostSetVar) > 0)
		ModifyControl $popInfo.hostSetVar,win=$popInfo.hostWindow,userData(popupWSInfo)=infoString
	endif
end
