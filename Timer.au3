#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icons\timer.ico
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Comment=Sets timer and warns.
#AutoIt3Wrapper_Res_Description=Sets timer and warns.
#AutoIt3Wrapper_Res_Fileversion=1.1.0.11
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=Conrad Zelck
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Language=1031
#AutoIt3Wrapper_Res_Field=Copyright|Conrad Zelck
#AutoIt3Wrapper_Res_Field=Compile Date|%date% %time%
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include <WinSnap.au3>
#include <TrayCox.au3> ; source: https://github.com/SimpelMe/TrayCox

OnAutoItExitRegister("_ExitUnRegister")

Local $bGUI = 1 ; gui is visible
Global $hEnableGUI = TrayCreateItem("Verstecken", -1, 2)
TrayItemSetOnEvent (-1, "_Hide")
TrayCreateItem("", -1, 3)

Global $g_iCountMon = _CountMon() ; needed for _GuiPos...
Global $g_iPosX, $g_iPosY ; needed for _GuiPos...

Global $g_iRemain = 1 ; remaining time in ms - set to something different then 0

Local $sZeit = InputBox("Timer setzen", "Erlaubte Zeichen: 1234567890hms:.,-" & @CRLF & @CRLF & "M" & Chr(0xF6) & "glichkeiten:" & @CRLF & "[hmm]ss" & @CRLF & "1h / 30m / 1h30" & @CRLF & "1:30: / 1.. / 30," , "59")
If @error Then Exit
$sZeit = StringReplace($sZeit, ".", ":") ; is a valid delimiter due to quick input
$sZeit = StringReplace($sZeit, ",", ":") ; is a valid delimiter due to quick input
$sZeit = StringReplace($sZeit, "-", ":") ; is a valid delimiter due to quick input

If StringRegExp($sZeit, "(?i)[^hms\d:]") Then ; only digits h, m, s or delimiter above allowed
	MsgBox($MB_TOPMOST, "Fehler", "Es wurden unerlaubte Zeichen benutzt.")
	Exit
EndIf

Local $iSec = 0, $iMin = 0, $iHour = 0, $iCount = 2
Local $aZeit
If StringInStr($sZeit, ":") Then ; divided by delimiter
	$aZeit = StringSplit($sZeit, ":")
	Switch $aZeit[0]
		Case 1
			$iSec = Number($aZeit[1])
		Case 2
			$iMin = Number($aZeit[1])
			$iSec = Number($aZeit[2])
		Case Else ; to many delimiters are ignored
			$iHour = Number($aZeit[1])
			$iMin = Number($aZeit[2])
			$iSec = Number($aZeit[3])
	EndSwitch
ElseIf StringRegExp($sZeit, "(?i)^\d+$") Then ; digits only
	$iSec = Number(StringRight($sZeit, $iCount))
	$sZeit = StringTrimRight($sZeit, $iCount)
	$iMin = Number(StringRight($sZeit, $iCount))
	$sZeit = StringTrimRight($sZeit, $iCount)
	$iHour = Number($sZeit)
Else
	If StringRegExp($sZeit, "(?i)m(\d+)$") Then ; m (for minutes) with trailing digits
		$aZeit = StringRegExp($sZeit, "(?i)m(\d+)$", $STR_REGEXPARRAYMATCH)
		$iSec = $aZeit[0]
	EndIf
	If StringRegExp($sZeit, "(?i)(\d+)s") Then ; s (for seconds) with leading digits
		$aZeit = StringRegExp($sZeit, "(?i)(\d+)s", $STR_REGEXPARRAYMATCH)
		$iSec = $aZeit[0]
	EndIf
	If StringRegExp($sZeit, "(?i)(\d+)m") Then ; m (for minutes) with leading digits
		$aZeit = StringRegExp($sZeit, "(?i)(\d+)m", $STR_REGEXPARRAYMATCH)
		$iMin = $aZeit[0]
	EndIf
	If StringRegExp($sZeit, "(?i)h(\d+)$") Then ; h (for hours) with trailing digits
		$aZeit = StringRegExp($sZeit, "(?i)h(\d+)$", $STR_REGEXPARRAYMATCH)
		$iMin = $aZeit[0]
	EndIf
	If StringRegExp($sZeit, "(?i)(\d+)h") Then ; h (for hours) with leading digits
		$aZeit = StringRegExp($sZeit, "(?i)(\d+)h", $STR_REGEXPARRAYMATCH)
		$iHour = $aZeit[0]
	EndIf
EndIf

ConsoleWrite("H: " & $iHour & @TAB)
ConsoleWrite("M: " & $iMin & @TAB)
ConsoleWrite("S: " & $iSec & @CRLF)

Global $g_iMSec = $iSec * 1000 + $iMin * 60 * 1000 + $iHour * 60 * 60 * 1000
Global $g_iInit = TimerInit()

_GuiPosReadReg()
GUISetFont(Default, Default, Default, "Lucida Console")
Local $hGUI = GUICreate('Timer', 97, 20, $g_iPosX, $g_iPosY, $WS_POPUP + $WS_BORDER, $WS_EX_TOPMOST + $WS_EX_TOOLWINDOW); + $WS_EX_WINDOWEDGE)
Local $hDragLabel = GUICtrlCreateLabel("", 0, 0, 20, 20, -1, $GUI_WS_EX_PARENTDRAG) ; is on top in the size of the icon to drag and move the gui
Local $hBackground = GUICtrlCreateLabel("", 20, 0, 77, 20)
Local $hIcon
If @Compiled Then
	$hIcon = GUICtrlCreateIcon(@ScriptFullPath, -1, 2, 2, 16, 16)
Else
	$hIcon = GUICtrlCreateIcon(@ScriptDir & "\Icons\timer.ico", -1, 2, 2, 16, 16)
EndIf

Global $g_hSec = GUICtrlCreateLabel(_FormattedTime($g_iMSec), 20, 0, 77, 18, $SS_CENTER)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1, 14)
Local $hContextMenu = GUICtrlCreateContextMenu($hBackground)
Local $hContextMenuExit = GUICtrlCreateMenuItem("Timer beenden", $hContextMenu)

GUISetState(@SW_SHOW)
_WinSnap_Set($hGUI)
Global $g_aCurPos = WinGetPos($hGUI)
AdlibRegister("_UpdateTimer", 990)

While 1
	If $g_iRemain = 0 Then ExitLoop
	_GuiPosWriteReg()
	Switch GUIGetMsg()
		Case $hContextMenuExit
			Exit
	EndSwitch
WEnd

AdlibUnRegister("_UpdateTimer")
SoundSetWaveVolume(100)
SoundPlay(@WindowsDir & "\media\tada.wav")

Global $g_bRed = True
AdlibRegister("_Red")

While 1
	Switch GUIGetMsg()
		Case $hContextMenuExit
			Exit
	EndSwitch
WEnd
Exit

#region - Funcs
Func _Red()
	If $g_bRed Then
		GUICtrlSetBkColor($hBackground, 0xff0000)
	Else
		GUICtrlSetBkColor($hBackground, $GUI_BKCOLOR_TRANSPARENT)
	EndIf
	$g_bRed = Not $g_bRed
EndFunc

Func _UpdateTimer()
	$g_iRemain = $g_iMSec - TimerDiff($g_iInit)
	If $g_iRemain <= 0 Then $g_iRemain = 0
	GUICtrlSetData($g_hSec, _FormattedTime($g_iRemain))
EndFunc

Func _FormattedTime($iTime)
	Local $sTimeFormatted = StringFormat("%.2d:%.2d:%.2d", (Floor($iTime / 3600000)), (Floor(Mod($iTime,3600000) / 60000)), (Mod(Mod($iTime,3600000),60000) / 1000)); umgerechnet in hh:mm:ss
	Return $sTimeFormatted
EndFunc

Func _ExitUnRegister()
	AdlibUnRegister()
EndFunc

Func _Hide()
	If $bGUI = 1 Then
		GUISetState(@SW_HIDE,$hGUI )
		TrayItemSetText($hEnableGUI, "Anzeigen")
	Else
		GUISetState(@SW_SHOW,$hGUI )
		TrayItemSetText($hEnableGUI, "Verstecken")
	EndIf
	$bGUI = Not $bGUI
EndFunc

#region - Funcs _GuiPos...
Func _GuiPosReadReg()
	If $g_iCountMon = 1 Then
		$g_iPosX = RegRead("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosX")
		If @error Then
			$g_iPosX = RegRead("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosX_2")
			If @error Then
				$g_iPosX = -1
			EndIf
			If $g_iPosX > @DesktopWidth Then $g_iPosX -= @DesktopWidth
		EndIf
		$g_iPosY = RegRead("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosY")
		If @error Then
			$g_iPosY = RegRead("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosY_2")
			If @error Then
				$g_iPosY = -1
			EndIf
		EndIf
	Else
		$g_iPosX = RegRead("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosX_2")
		If @error Then
			RegRead("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosX")
			If @error Then
				$g_iPosX = -1
			EndIf
		EndIf
		$g_iPosY = RegRead("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosY_2")
		If @error Then
			RegRead("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosY")
			If @error Then
				$g_iPosY = -1
			EndIf
		EndIf
	EndIf
EndFunc

Func _GuiPosWriteReg()
	Local $aTempPos = WinGetPos($hGUI)
	If $g_iCountMon = 1 Then
		If $aTempPos[0] <> $g_aCurPos[0] Then RegWrite("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosX", "REG_DWORD", $aTempPos[0])
		If $aTempPos[1] <> $g_aCurPos[1] Then RegWrite("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosY", "REG_DWORD", $aTempPos[1])
	Else
		If $aTempPos[0] <> $g_aCurPos[0] Then RegWrite("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosX_2", "REG_DWORD", $aTempPos[0])
		If $aTempPos[1] <> $g_aCurPos[1] Then RegWrite("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosY_2", "REG_DWORD", $aTempPos[1])
	EndIf
EndFunc

Func _CountMon()
	Return _WinAPI_GetSystemMetrics(80) ; 80 is for SM_CMONITORS - visible Monitors in MSDN Library
EndFunc
#endregion - _GuiPos...
#endregion - Funcs