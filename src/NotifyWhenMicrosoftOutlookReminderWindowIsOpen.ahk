#SingleInstance, force

;==========================================================
; Constant Variables
;==========================================================
ApplicationVersionNumber := "v1.1.1"
AppResourcesDirectoryPath := A_ScriptDir . "\NotifyWhenMicrosoftOutlookReminderWindowIsOpenResources"
AppTrayIconFilePath := AppResourcesDirectoryPath . "\AppIcon.ico"	; Define where to unpack the mouse cursor image file to.
MouseCursorImageFilePath :=  AppResourcesDirectoryPath . "\MouseCursor.ani"	; Define where to unpack the mouse cursor image file to.
SettingsFilePath := AppResourcesDirectoryPath . "\Settings.ini"

;==========================================================
; Script Initialization
;==========================================================
InitializeScript(AppResourcesDirectoryPath, AppTrayIconFilePath, MouseCursorImageFilePath)

;==========================================================
; Settings - Specify the default settings, then load any existing settings from the settings file.
;==========================================================
Settings := {}	; Objects can be accessed with both associated array syntax (brackets) and object syntax (dots).
Settings.ShowIconInSystemTray := { Value: true, Category: "General" }
Settings.PromptUserToViewSettingsFileOnStartup := { Value: false, Category: "Startup" }
Settings.ShowWindowsNotificationOnStartup := { Value: true, Category: "Startup" }
Settings.ShowWindowsNotificationAlert := { Value: true, Category: "Windows Notification Alert" }
Settings.PlaySoundOnWindowsNotificationAlert := { Value: true, Category: "Windows Notification Alert" }
Settings.ShowTooltipAlert := { Value: true, Category: "Tooltip Alert" }
Settings.MillisecondsToShowTooltipAlertFor := { Value: 4000, Category: "Tooltip Alert" }
Settings.ChangeMouseCursorOnAlert := { Value: true, Category: "Mouse Cursor Alert" }
Settings.ShowTransparentWindowAlert := { Value: true, Category: "Transparent Window Alert" }
Settings.MillisecondsToShowTransparentWindowAlertFor := { Value: 3000, Category: "Transparent Window Alert" }
Settings.SecondsBeforeAlertsAreReTriggeredWhenOutlookRemindersWindowIsStillOpen := { Value: 30, Category: "General" }
Settings.EnsureOutlookRemindersWindowIsRestored := { Value: true, Category: "Outlook Reminders Window" }
Settings.EnsureOutlookRemindersWindowIsAlwaysOnTop := { Value: true, Category: "Outlook Reminders Window" }
Settings.OutlookRemindersWindowTitleTextToMatch := { Value: "Reminder(s)", Category: "Window Detection" }
Settings.OutlookProcessName := { Value: "Outlook.exe", Category: "Window Detection" }
Settings := LoadSettingsFromFileIfExistsOrCreateFile(SettingsFilePath, Settings)

;==========================================================
; App Startup
;==========================================================
AddSettingsMenuToSystemTray()

if ((Settings.PromptUserToViewSettingsFileOnStartup).Value)
{
	PromptUserToAdjustSettingsAndGetUpdatedSettings(SettingsFilePath, Settings, ApplicationVersionNumber)
}

ApplyStartupSettings(Settings)
SetTitleMatchMode 2	; Use "title contains text" mode to match windows.

;==========================================================
; Main Loop
;==========================================================
Loop
{
	; Copy required settings values into local variables to be easily used.
	outlookRemindersWindowTitleTextToMatch := (Settings.OutlookRemindersWindowTitleTextToMatch).Value
	outlookProcessName := (Settings.OutlookProcessName).Value
	secondsToWaitForWindowToBeClosed := (Settings.SecondsBeforeAlertsAreReTriggeredWhenOutlookRemindersWindowIsStillOpen).Value

	; Get the ID of the window if it does indeed belong to the Outlook process.
	outlookRemindersWindowId := GetOutlookRemindersWindowId(outlookRemindersWindowTitleTextToMatch,outlookProcessName)

	; If the found window doesn't belong to Outlook.exe, keep waiting for the actual Outlook reminders window.
	if (outlookRemindersWindowId = 0)
	{
		Sleep, 10000
		continue
	}

	; Display any alerts about the window appearing.
	TriggerAlerts(Settings, MouseCursorImageFilePath)

	; Wait for the window to close, or for the timeout period to elapse.
	WinWaitClose, ahk_id %outlookRemindersWindowId%, , %secondsToWaitForWindowToBeClosed%

	; If the window was closed, clear any remaining alerts about the window having appeared.
	outlookRemindersWindowId := GetOutlookRemindersWindowId(outlookRemindersWindowTitleTextToMatch, outlookProcessName)
	outlookRemindersWindowWasClosed := (outlookRemindersWindowId = 0)
	if (outlookRemindersWindowWasClosed = true)
	{
		ClearAlerts()
	}
}

;==========================================================
; Labels
;==========================================================

ShowSettingsWindowAndProvideParameters:
	ShowSettingsWindow(SettingsFilePath, Settings, ApplicationVersionNumber)
return

;==========================================================
; Functions
;==========================================================

InitializeScript(appResourcesDirectoryPath, appTrayIconFilePath, mouseCursorImageFilePath)
{
	; Ensure the directory to create files in and read from exists.
	FileCreateDir, %appResourcesDirectoryPath%

	; Ensure that any images embedded in the script have been extracted into files.
	CreateAppIconFileIfItDoesNotExist(appTrayIconFilePath)
	CreateMouseCursorImageFileIfItDoesNotExist(mouseCursorImageFilePath)

	; Set the system tray icon to use for this script.
	Menu, Tray, Icon, %appTrayIconFilePath%

	; Before exiting the script ensure that all alerts have been cleared (mouse cursor restored, etc.)
	OnExit("ClearAlerts")
}

CreateAppIconFileIfItDoesNotExist(appIconFilePath)
{
	if !FileExist(appIconFilePath)
	{
		Extract_AppIconFile(appIconFilePath)
	}
}

CreateMouseCursorImageFileIfItDoesNotExist(mouseCursorImageFilePath)
{
	if !FileExist(mouseCursorImageFilePath)
	{
		Extract_MouseCursorImageFile(mouseCursorImageFilePath)
	}
}

AddSettingsMenuToSystemTray()
{
	Menu, Tray, Add
	Menu, Tray, Add, Settings, ShowSettingsWindowAndProvideParameters
}

LoadSettingsFromFileIfExistsOrCreateFile(settingsFilePath, settings)
{
	settingsFileAlreadyExisted := true

	; If the settings file exists, read it's contents into the settings object.
	If (FileExist(settingsFilePath))
	{
		settings := LoadSettingsFromFile(settingsFilePath, settings)
	}
	else
	{
		settingsFileAlreadyExisted := false
	}

	; Save the settings after loading them in order to make sure the settings file is created if it doesn't exist, and so any new settings added in a new version get written to the file.
	SaveSettingsToFile(settingsFilePath, settings)

	; If the settings file did not previously exist, the user likely has not seen the settings yet, so mark that we should prompt them to view them.
	if (!settingsFileAlreadyExisted)
	{
		(settings.PromptUserToViewSettingsFileOnStartup).Value := true
	}

	; Return the settings that were loaded.
	return settings
}

LoadSettingsFromFile(settingsFilePath, settings)
{
	for settingName, obj in settings
	{
		value := obj.Value
		category := obj.Category
		IniRead, valueReadIn, %settingsFilePath%, %category%, %settingName%, %value%
		obj.Value := valueReadIn
	}
	return settings
}

SaveSettingsToFile(settingsFilePath, settings)
{
	; Delete the settings file so it is fresh when we write to it.
	DeleteFile(settingsFilePath)

	; Write the settings to the file (will be created automatically if needed).
	for settingName, obj in settings
	{
		value := obj.Value
		category := obj.Category
		IniWrite, %value%, %settingsFilePath%, %category%, %settingName%
	}
}

DeleteFile(filePath)
{
	If (FileExist(filePath))
	{
		FileDelete, %filePath%
	}
}

PromptUserToAdjustSettingsAndGetUpdatedSettings(settingsFilePath, settings, applicationVersionNumber)
{
	; Options parameter 4 == Yes/No prompt.
	MsgBox, 4, Open Settings?, It seems this is the first time launching the Notify When Microsoft Outlook Reminder Window Is Open application.`n`nWould you like to view the settings?

	IfMsgBox, Yes
	{
		ShowSettingsWindow(settingsFilePath, settings, applicationVersionNumber)
	}
}

ApplyStartupSettings(settings)
{
	ShowAHKScriptIconInSystemTray((settings.ShowIconInSystemTray).Value)

	if ((Settings.ShowWindowsNotificationOnStartup).Value)
	{
		ShowTrayTip("Notify When Microsoft Outlook Reminder Window Is Open", "Now monitoring for the Outlook Reminders window to appear", false)
	}
}

ShowAHKScriptIconInSystemTray(showIconInSystemTray)
{
	; If we should show the Tray Icon.
	if (showIconInSystemTray)
	{
		Menu, Tray, Icon
	}
	; Else hide the Tray Icon.
	else
	{
		Menu, Tray, NoIcon
	}
}

GetOutlookRemindersWindowId(outlookRemindersWindowTitleTextToMatch, outlookProcessName)
{
	; Get all of the windows that belong to the Outlook process so we can check if the found window does.
	WinGet, outlookWindowIds, List, ahk_exe %outlookProcessName%

	; Get the ID of the found windows.
	WinGet, reminderWindowIds, List, %outlookRemindersWindowTitleTextToMatch%

	; Determine if one of the found windows belongs to the Outlook process or not and return it's ID if it does.
	outlookRemindersWindowId := 0
	Loop, %outlookWindowIds%
	{
		outlookWindowId := outlookWindowIds%A_Index%
		Loop, %reminderWindowIds%
		{
			reminderWindowId := reminderWindowIds%A_Index%
			if (outlookWindowId = reminderWindowId)
			{
				outlookRemindersWindowId := reminderWindowId
				break 2
			}
		}
	}
	return outlookRemindersWindowId
}

TriggerAlerts(settings, mouseCursorImageFilePath)
{
	; Copy required settings values into local variables to be easily used.
	outlookRemindersWindowTitleTextToMatch := (settings.OutlookRemindersWindowTitleTextToMatch).Value

	if ((settings.EnsureOutlookRemindersWindowIsRestored).Value)
	{
		WinRestore, %outlookRemindersWindowTitleTextToMatch%	; Make sure the window is not minimized or maximized.
	}

	if ((settings.EnsureOutlookRemindersWindowIsAlwaysOnTop).Value)
	{
		WinSet, AlwaysOnTop, on, %outlookRemindersWindowTitleTextToMatch%
	}

	if ((settings.ShowWindowsNotificationAlert).Value)
	{
		ShowTrayTip("Outlook Reminder", "You have an Outlook reminder open", (settings.PlaySoundOnWindowsNotificationAlert).Value)
	}

	if ((settings.ShowTooltipAlert).Value)
	{
		ShowToolTip("You have an Outlook reminder open", (settings.MillisecondsToShowTooltipAlertFor).Value)
	}

	if ((settings.ChangeMouseCursorOnAlert).Value)
	{
		SetSystemMouseCursor(mouseCursorImageFilePath)
	}

	if ((settings.ShowTransparentWindowAlert).Value)
	{
		ShowTransparentWindow("You have an Outlook reminder open", "", (settings.MillisecondsToShowTransparentWindowAlertFor).Value)
	}
}

ShowTrayTip(title, message, playSound)
{
	trayTipOptions := 0
	if (!playSound)
	{
		trayTipOptions := 16
	}
	TrayTip, %title%, %message%, , %trayTipOptions%
}

ShowToolTip(textToDisplay, numberOfMillisecondsToShowToolTipFor)
{
	ToolTip, %textToDisplay%,,,
	SetTimer, HideToolTip, -%numberOfMillisecondsToShowToolTipFor%	; Only show the tooltip for the specified amount of time.
}

ShowTransparentWindow(title, text, numberOfMillisecondsToShowWindowFor)
{
	titleFontSize := 24
	textFontSize := 16

	; Shrink the margin so that the text goes up close to the edge of the window border.
	windowMargin := titleFontSize * 0.1

	Gui 3:Default	; Specify that these controls are for window #3.

	; Create the transparent window to display the text
	backgroundColor = DDDDDD  ; Can be any RGB color (it will be made transparent below).
	Gui +LastFound +AlwaysOnTop -Caption +ToolWindow +Border  ; +ToolWindow avoids a taskbar button and an alt-tab menu item.
	Gui, Margin, %windowMargin%, %windowMargin%
	Gui, Color, %backgroundColor%
	Gui, Font, s%titleFontSize% bold
	Gui, Add, Text,, %title%
	Gui, Font, s%textFontSize% norm
	if (text != "")
		Gui, Add, Text,, %text%
	WinSet, TransColor, FFFFFF 180	; Make all pixels of this color transparent (shouldn't be any with color FFFFFF) and make all other pixels semi-transparent.
	Gui, Show, AutoSize Center NoActivate  ; NoActivate avoids deactivating the currently active window.

	; Set the window to close after the given duration.
	SetTimer, CloseTransparentWindow, %numberOfMillisecondsToShowWindowFor%
}

CloseTransparentWindow()
{
	SetTimer, CloseTransparentWindow, Off	; Make sure the timer doesn't fire again.
	Gui, 3:Destroy							; Close the GUI, but leave the script running. Transparent window is window #3.
}

ClearAlerts()
{
	HideToolTip()
	RestoreDefaultMouseCursors()
	CloseTransparentWindow()
}

HideToolTip()
{
	ToolTip
}

ShowSettingsWindow(settingsFilePathParameter, settingsParameter, applicationVersionNumber)
{
	; Variables used for controls must be global, so define the global variables to use in the controls.
	global settingsFilePath, settings, showSystemTrayIcon, showWindowsNotificationOnStartup, showWindowsNotificationAlert, playSoundOnWindowsNotificationAlert, showTooltipAlert, millisecondsToShowTooltipAlertFor, changeMouseCursorOnAlert, showTransparentWindowAlert, millisecondsToShowTransparentWindowAlertFor, secondsBeforeAlertsAreReTriggeredWhenOutlookRemindersWindowIsStillOpen, ensureOutlookRemindersWindowIsRestored, ensureOutlookRemindersWindowIsAlwaysOnTop, outlookRemindersWindowTitleTextToMatch, outlookProcessName

	settingsFilePath := settingsFilePathParameter
	settings := settingsParameter

	; Get the values to show in the controls from the Settings.
	showSystemTrayIcon := (settings.ShowIconInSystemTray).Value
	showWindowsNotificationOnStartup := (settings.ShowWindowsNotificationOnStartup).Value
	showWindowsNotificationAlert := (settings.ShowWindowsNotificationAlert).Value
	playSoundOnWindowsNotificationAlert := (settings.PlaySoundOnWindowsNotificationAlert).Value
	showTooltipAlert := (settings.ShowTooltipAlert).Value
	millisecondsToShowTooltipAlertFor := (settings.MillisecondsToShowTooltipAlertFor).Value
	changeMouseCursorOnAlert := (settings.ChangeMouseCursorOnAlert).Value
	showTransparentWindowAlert := (settings.ShowTransparentWindowAlert).Value
	millisecondsToShowTransparentWindowAlertFor := (settings.MillisecondsToShowTransparentWindowAlertFor).Value
	secondsBeforeAlertsAreReTriggeredWhenOutlookRemindersWindowIsStillOpen := (settings.SecondsBeforeAlertsAreReTriggeredWhenOutlookRemindersWindowIsStillOpen).Value
	ensureOutlookRemindersWindowIsRestored := (settings.EnsureOutlookRemindersWindowIsRestored).Value
	ensureOutlookRemindersWindowIsAlwaysOnTop := (settings.EnsureOutlookRemindersWindowIsAlwaysOnTop).Value
	outlookRemindersWindowTitleTextToMatch := (settings.OutlookRemindersWindowTitleTextToMatch).Value
	outlookProcessName := (settings.OutlookProcessName).Value

	Gui 2:Default	; Specify that these controls are for window #2.

	; Create the GUI.
	Gui, +AlwaysOnTop +Owner ToolWindow ; +Owner avoids a taskbar button ; +OwnDialogs makes any windows launched by this one modal ; ToolWindow makes border smaller and hides the min/maximize buttons.

	; Determine if certain controls should be disabled or not.
	windowsNotificationAlertsAreDisabled := !showWindowsNotificationAlert
	tooltipAlertsAreDisabled := !showTooltipAlert
	transparentWindowAlertsAreDisabled := !showTransparentWindowAlert

	; Add the controls to the GUI.
	Gui, Add, GroupBox, x10 w525 r3, General Settings:	; r3 means 3 rows tall.
		Gui, Add, Checkbox, yp+25 x20 vshowSystemTrayIcon gShowSystemTrayIconToggled Checked%showSystemTrayIcon%, Show icon in the system tray

		Gui, Add, Text, yp+25 x20, Seconds before alerts are re-triggered when Outlook reminder window is still open:
		Gui, Add, Edit, x+5
		Gui, Add, UpDown, vsecondsBeforeAlertsAreReTriggeredWhenOutlookRemindersWindowIsStillOpen Range30-3600, %secondsBeforeAlertsAreReTriggeredWhenOutlookRemindersWindowIsStillOpen%

	Gui, Add ,GroupBox, x10 w525 r2, Startup Settings:
		Gui, Add, Checkbox, yp+25 x20 vshowWindowsNotificationOnStartup Checked%showWindowsNotificationOnStartup%, Show Windows notification at startup

	Gui, Add ,GroupBox, x10 w525 r3, Outlook Reminders Window:
		Gui, Add, Checkbox, yp+25 x20 vensureOutlookRemindersWindowIsRestored Checked%ensureOutlookRemindersWindowIsRestored%, Ensure Outlook reminders window is not minimized
		Gui, Add, Checkbox, yp+25 x20 vensureOutlookRemindersWindowIsAlwaysOnTop Checked%ensureOutlookRemindersWindowIsAlwaysOnTop%, Ensure Outlook reminders window is on top of all other windows

	Gui, Add ,GroupBox, x10 w525 r3, Windows Notification Alerts:
		Gui, Add, Checkbox, yp+25 x20 vshowWindowsNotificationAlert gShowWindowsNotificationAlertToggled Checked%showWindowsNotificationAlert%, Show Windows notification alert
		Gui, Add, Checkbox, yp+25 x20 vplaySoundOnWindowsNotificationAlert Checked%playSoundOnWindowsNotificationAlert% Disabled%windowsNotificationAlertsAreDisabled%, Play sound on alert

	Gui, Add ,GroupBox, x10 w525 r3, Tooltip Alerts:
		Gui, Add, Checkbox, yp+25 x20 vshowTooltipAlert gShowTooltipAlertToggled Checked%showTooltipAlert%, Show Tooltip alert

		Gui, Add, Text, yp+25 x20, Milliseconds to show tooltip for
		Gui, Add, Edit, x+5
		Gui, Add, UpDown, yp+25 x20 vmillisecondsToShowTooltipAlertFor Range1-60000 Disabled%tooltipAlertsAreDisabled%, %millisecondsToShowTooltipAlertFor%

	Gui, Add ,GroupBox, x10 w525 r2, Mouse Cursor Alerts:
		Gui, Add, Checkbox, yp+25 x20 vchangeMouseCursorOnAlert Checked%changeMouseCursorOnAlert%, Change mouse cursor while Outlook reminders window is open

	Gui, Add ,GroupBox, x10 w525 r3, Transparent Window Alerts:
		Gui, Add, Checkbox, yp+25 x20 vshowTransparentWindowAlert gShowTransparentWindowAlertToggled Checked%showTransparentWindowAlert%, Show transparent window alert

		Gui, Add, Text, yp+25 x20, Milliseconds to show transparent window for
		Gui, Add, Edit, x+5
		Gui, Add, UpDown, yp+25 x20 vmillisecondsToShowTransparentWindowAlertFor Range1-60000 Disabled%transparentWindowAlertsAreDisabled%, %millisecondsToShowTransparentWindowAlertFor%

	Gui, Add ,GroupBox, x10 w525 r3, Window Detection Settings:
		Gui, Add, Text, yp+25 x20, Window title text to match against (default is "Reminder(s)"):
		Gui, Add, Edit, x+5 r1 w200 voutlookRemindersWindowTitleTextToMatch, %outlookRemindersWindowTitleTextToMatch%

		Gui, Add, Text, yp+25 x20, Outlook process name (default is "Outlook.exe"):
		Gui, Add, Edit, x+5 r1 w200 voutlookProcessName, %outlookProcessName%

	Gui, Add, Link, x10, <a href="https://github.com/deadlydog/NotifyWhenMicrosoftOutlookReminderWindowIsOpen">View project homepage and documentation</a>

	Gui, Add, Button, gSettingsCancelButton xm w100, Cancel
	Gui, Add, Button, gRestoreDefaultSettingsButton x+200 w100, Restore Defaults
	Gui, Add, Button, gSettingsSaveButton x+25 w100, Save

	; Show the GUI, set focus to the input box, and wait for input.
	Gui, Show, AutoSize Center, Notify When Outlook Reminder Window Is Open %applicationVersionNumber% - Settings

	return  ; End of auto-execute section. The script is idle until the user does something.

	ShowSystemTrayIconToggled:
		Gui 2:Submit, NoHide	; Get the values from the GUI controls without closing the GUI.

		if (!showSystemTrayIcon)
		{
			; For options: 4096 (always on top) + 48 (exclamation icon) = 4144
			MsgBox, 4144, Warning, If you disable the system tray icon the only way to access the settings again will be to manually edit (or simply delete) the settings file located at:`n`n%settingsFilePath%
		}
	return

	ShowWindowsNotificationAlertToggled:
		Gui 2:Submit, NoHide	; Get the values from the GUI controls without closing the GUI.

		; Enable or disable other settings controls based on if the alert is enabled or not.
		if (showWindowsNotificationAlert)
			GuiControl, Enable, playSoundOnWindowsNotificationAlert
		else
			GuiControl, Disable, playSoundOnWindowsNotificationAlert
	return

	ShowTooltipAlertToggled:
		Gui 2:Submit, NoHide	; Get the values from the GUI controls without closing the GUI.

		; Enable or disable other settings controls based on if the alert is enabled or not.
		if (showTooltipAlert)
			GuiControl, Enable, millisecondsToShowTooltipAlertFor
		else
			GuiControl, Disable, millisecondsToShowTooltipAlertFor
	return

	ShowTransparentWindowAlertToggled:
		Gui 2:Submit, NoHide	; Get the values from the GUI controls without closing the GUI.

		; Enable or disable other settings controls based on if the alert is enabled or not.
		if (showTransparentWindowAlert)
			GuiControl, Enable, millisecondsToShowTransparentWindowAlertFor
		else
			GuiControl, Disable, millisecondsToShowTransparentWindowAlertFor
	return

	OpenProjectUrlButton:	; Go to project URL button was clicked.
		Run, https://github.com/deadlydog/NotifyWhenMicrosoftOutlookReminderWindowIsOpen
	return

	SettingsSaveButton:		; Settings Save button was clicked.
		Gui 2:Submit, NoHide	; Get the values from the GUI controls without closing the GUI.
		(settings.ShowIconInSystemTray).Value := showSystemTrayIcon
		(settings.ShowWindowsNotificationOnStartup).Value := showWindowsNotificationOnStartup
		(settings.ShowWindowsNotificationAlert).Value := showWindowsNotificationAlert
		(settings.PlaySoundOnWindowsNotificationAlert).Value := playSoundOnWindowsNotificationAlert
		(settings.ShowTooltipAlert).Value := showTooltipAlert
		(settings.MillisecondsToShowTooltipAlertFor).Value := millisecondsToShowTooltipAlertFor
		(settings.ChangeMouseCursorOnAlert).Value := changeMouseCursorOnAlert
		(settings.ShowTransparentWindowAlert).Value := showTransparentWindowAlert
		(settings.MillisecondsToShowTransparentWindowAlertFor).Value := millisecondsToShowTransparentWindowAlertFor
		(settings.SecondsBeforeAlertsAreReTriggeredWhenOutlookRemindersWindowIsStillOpen).Value := secondsBeforeAlertsAreReTriggeredWhenOutlookRemindersWindowIsStillOpen
		(settings.EnsureOutlookRemindersWindowIsRestored).Value := ensureOutlookRemindersWindowIsRestored
		(settings.EnsureOutlookRemindersWindowIsAlwaysOnTop).Value := ensureOutlookRemindersWindowIsAlwaysOnTop
		(settings.OutlookRemindersWindowTitleTextToMatch).Value := outlookRemindersWindowTitleTextToMatch
		(settings.OutlookProcessName).Value := outlookProcessName
		(settings.PromptUserToViewSettingsFileOnStartup).Value := false	; The user has seen the settings, so we don't need to prompt them to see them again.
		SaveSettingsToFile(settingsFilePath, settings)	; Save the settings before loading them again.
		Reload	; Reload the script to apply the new settings.
	return

	RestoreDefaultSettingsButton:
		DeleteFile(settingsFilePath)
		Reload	; Reload the script to apply the new settings.
	return

	SettingsCancelButton:	; Settings Cancel button was clicked.
	2GuiClose:				; The window was closed (by clicking X or through task manager).
	2GuiEscape:				; The Escape key was pressed.
		Gui, 2:Destroy		; Close the GUI, but leave the script running.
	return
}

;----------------------------------------------------------
; How to replace curosr: https://autohotkey.com/board/topic/32608-changing-the-system-cursor/
;----------------------------------------------------------
SetSystemMouseCursor(imageFilePath)
{
	Cursor := imageFilePath
	CursorHandle := DllCall( "LoadCursorFromFile", Str, Cursor )

	Cursors = 32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,32651
	Loop, Parse, Cursors, `,
	{
		DllCall( "SetSystemCursor", Uint, CursorHandle, Int, A_Loopfield )
	}
}

RestoreDefaultMouseCursors()
{
	SPI_SETCURSORS := 0x57
	DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS, UInt,0, UInt,0, UInt,0 )
}

;----------------------------------------------------------
; Pack external files into ahk script: https://autohotkey.com/board/topic/64481-include-virtually-any-file-in-a-script-exezipdlletc/
; Bell cursor image: http://www.rw-designer.com/cursor-detail/91307
;----------------------------------------------------------
MouseCursorImageFile_Get(_What)
{
	Static Size = 34420, Name = "MouseCursor.ani", Extension = "ani", Directory = "C:\dev\Git\NotifyWhenMicrosoftOutlookReminderWindowIsOpen\src\NotifyWhenMicrosoftOutlookReminderWindowIsOpenResources"
	, Options = "Size,Name,Extension,Directory"
	;This function returns the size(in bytes), name, filename, extension or directory of the file stored depending on what you ask for.
	If (InStr("," Options ",", "," _What ","))
		Return %_What%
}

Extract_MouseCursorImageFile(_Filename, _DumpData = 0)
{
	;This function "extracts" the file to the location+name you pass to it.
	Static HasData = 1, Out_Data, Ptr, ExtractedData
	Static 1 = "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"
	Static 2 = "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"
	Static 3 = "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"

	If (!HasData)
		Return -1

	If (!ExtractedData){
		ExtractedData := True
		, Ptr := A_IsUnicode ? "Ptr" : "UInt"
		, VarSetCapacity(TD, 47156 * (A_IsUnicode ? 2 : 1))

		Loop, 3
			TD .= %A_Index%, %A_Index% := ""

		VarSetCapacity(Out_Data, Bytes := 34420, 0)
		, DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &TD, "UInt", 0, "UInt", 1, Ptr, &Out_Data, A_IsUnicode ? "UIntP" : "UInt*", Bytes, "Int", 0, "Int", 0, "CDECL Int")
		, TD := ""
	}

	IfExist, %_Filename%
		FileDelete, %_Filename%

	h := DllCall("CreateFile", Ptr, &_Filename, "Uint", 0x40000000, "Uint", 0, "UInt", 0, "UInt", 4, "Uint", 0, "UInt", 0)
	, DllCall("WriteFile", Ptr, h, Ptr, &Out_Data, "UInt", 34420, "UInt", 0, "UInt", 0)
	, DllCall("CloseHandle", Ptr, h)

	If (_DumpData)
		VarSetCapacity(Out_Data, 34420, 0)
		, VarSetCapacity(Out_Data, 0)
		, HasData := 0
}


;----------------------------------------------------------
; Pack external files into ahk script: https://autohotkey.com/board/topic/64481-include-virtually-any-file-in-a-script-exezipdlletc/
; Bell icon image: https://icons8.com/icon/set/alert/all
;----------------------------------------------------------
AppIconFile_Get(_What)
{
	Static Size = 34494, Name = "appIcon.ico", Extension = "ico", Directory = "C:\dev\Git\NotifyWhenMicrosoftOutlookReminderWindowIsOpen\src\NotifyWhenMicrosoftOutlookReminderWindowIsOpenResources"
	, Options = "Size,Name,Extension,Directory"
	;This function returns the size(in bytes), name, filename, extension or directory of the file stored depending on what you ask for.
	If (InStr("," Options ",", "," _What ","))
		Return %_What%
}

Extract_AppIconFile(_Filename, _DumpData = 0)
{
	;This function "extracts" the file to the location+name you pass to it.
	Static HasData = 1, Out_Data, Ptr, ExtractedData
	Static 1 = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAn2SNAJ9kjQCfZI0An2SNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAnGiMAJxq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"
	Static 2 = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD///////8AAP///////wAA////////AAD///////8AAP///////wAA///wD///AAD//+AH//8AAP//4Af//wAA///AA///AAD+AAAAAH8AAPwAAAAAPwAA/AAAAAA/AAD8AAAAAD8AAPwAAAAAPwAA/gAAAAB/AAD+AAAAAH8AAP8AAAAA/wAAxwAAAADjAADHgAAAAeMAAIRAAAACIQAAiEAAAAIRAAAIQAAAAhAAAAjAAAADEAAAEOAAAAcIAAAQ4AAABwgAABHgAAAHiAAAEeAAAAeIAAAR4AAAB4gAABHgAAAHiAAAEeAAAAeIAAAR4AAAB4gAABHgAAAHiAAAEfAAAA+IAAAR8AAAD4gAABDwAAAPCAAACPgAAB8QAAAIfAAAPhAAAIh8AAA+EQAAhH8AAP4hAACEf4AB/iEAAMf/4Yf/4wAAx//wD//jAAD///AP//8AAP///////wAA////////AAD///////8AAP///////wAA////////AAAoAAAAQAAAAIAAAAABACAAAAAAAABAAADDDgAAww4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA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jf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+ea4zvnmyNlKlxjQkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACfa4yVn2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fbI3/n2yN/59sjf+fa4yVAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAnmuM759sjf+ZvN//l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5m83/+fbI3/nmuM7wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJ5sjemfbI3/mbze/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT9v+X0/b/l9P2/5fT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"
	Static 3 = "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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//////////////////////////////////////////////////////////////////////////////8A/////////gB////////8AD////////gAH///////+AAf///////4AB/////4AAAAAAAf//gAAAAAAB//+AAAAAAAH//4AAAAAAAf//gAAAAAAB//+AAAAAAAH//8AAAAAAA///wAAAAAAD///gAAAAAAf///AAAAAAD//j8AAAAAAPx+P4AAAAAB/Hw/gAAAAAH8PDjAAAAAAxw8cMAAAAADDjhxwAAAAAOOGOHAAAAAA4cY4+AAAAAHxxDj4AAAAAfHAcPgAAAAB8OBx+AAAAAH44HH4AAAAAfjgcfgAAAAB+OBx+AAAAAH44HH4AAAAAfjgcfwAAAAD+OBx/AAAAAP44HH8AAAAA/jgcfwAAAAD+OBx/AAAAAP44HH8AAAAA/jgcf4AAAAH+OBw/gAAAAfw4Dj/AAAAD/HCOP8AAAAP8cY4f4AAAB/hxhx/wAAAP+OHHD/gAAB/w48OP/AAAP/HDw///AAD//8Pj///Dw///x+P//+PH///H////4Af////////gB///////////////////////////////////////////////////////////////////////////////"

	If (!HasData)
		Return -1

	If (!ExtractedData){
		ExtractedData := True
		, Ptr := A_IsUnicode ? "Ptr" : "UInt"
		, VarSetCapacity(TD, 47257 * (A_IsUnicode ? 2 : 1))

		Loop, 3
			TD .= %A_Index%, %A_Index% := ""

		VarSetCapacity(Out_Data, Bytes := 34494, 0)
		, DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &TD, "UInt", 0, "UInt", 1, Ptr, &Out_Data, A_IsUnicode ? "UIntP" : "UInt*", Bytes, "Int", 0, "Int", 0, "CDECL Int")
		, TD := ""
	}

	IfExist, %_Filename%
		FileDelete, %_Filename%

	h := DllCall("CreateFile", Ptr, &_Filename, "Uint", 0x40000000, "Uint", 0, "UInt", 0, "UInt", 4, "Uint", 0, "UInt", 0)
	, DllCall("WriteFile", Ptr, h, Ptr, &Out_Data, "UInt", 34494, "UInt", 0, "UInt", 0)
	, DllCall("CloseHandle", Ptr, h)

	If (_DumpData)
		VarSetCapacity(Out_Data, 34494, 0)
		, VarSetCapacity(Out_Data, 0)
		, HasData := 0
}
