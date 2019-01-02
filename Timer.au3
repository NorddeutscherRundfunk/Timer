#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icons\timer.ico
#AutoIt3Wrapper_Res_Comment=Sets timer and warns.
#AutoIt3Wrapper_Res_Description=Sets timer and warns.
#AutoIt3Wrapper_Res_Fileversion=1.0.0.9
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=Conrad Zelck
#AutoIt3Wrapper_Res_Language=1031
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>
#include <WinSnap.au3> ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <TrayCox.au3>

OnAutoItExitRegister("_ExitUnRegister")

Local $bGUI = 1
Global $hEnableGUI = TrayCreateItem("Verstecken", -1, 2)
TrayItemSetOnEvent (-1, "_Hide")
TrayCreateItem("", -1, 3)

Global $g_iCountMon = _CountMon() ; nötig für _GuiPos...
Global $g_iPosX, $g_iPosY ; nötig für _GuiPos...

Global $g_iRemain ; Remaining Time in ms

Local $sZeit = InputBox("Eingabe", @CRLF & "Timer setzen:" & @CRLF & @CRLF & "(h:mm:)ss" , "59")
If @error Then Exit
$sZeit = StringReplace($sZeit, ":", "")
If Number($sZeit) = 0 Then Exit
Local $iSec = Number(StringRight($sZeit, 2))
$sZeit = StringTrimRight($sZeit, 2)
Local $iMin = Number(StringRight($sZeit, 2))
$sZeit = StringTrimRight($sZeit, 2)
Local $iHour = Number(StringRight($sZeit, 2))

Global $g_iMSec = $iSec * 1000 + $iMin * 60 * 1000 + $iHour * 60 * 60 * 1000
Global $g_iInit = TimerInit()

_GuiPosReadReg()
GUISetFont(Default, Default, Default, "Lucida Console")
Local $hGUI = GUICreate('Timer', 97, 20, $g_iPosX, $g_iPosY, $WS_POPUP + $WS_BORDER, $WS_EX_TOPMOST + $WS_EX_TOOLWINDOW); + $WS_EX_WINDOWEDGE)
Local $hDragLabel = GUICtrlCreateLabel("", 0, 0, 20, 20, -1, $GUI_WS_EX_PARENTDRAG) ; liegt als erstes und hat die Größe des Iconplatzes und ist der Anfasser zum Verschieben
Local $hBackground = GUICtrlCreateLabel("", 20, 0, 77, 20)
Local $hIcon
If @Compiled Then
	$hIcon = GUICtrlCreateIcon(@ScriptFullPath, -1, 2, 2, 16, 16)
Else
	$hIcon = GUICtrlCreateIcon(@ScriptDir & "\Icons\timer.ico", -1, 2, 2, 16, 16)
EndIf

Local $hSEC = GUICtrlCreateLabel(_Dauer($g_iMSec), 20, 0, 77, 18, $SS_CENTER)
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetFont(-1, 14)

GUISetState(@SW_SHOW)
_WinSnap_Set($hGUI)
Global $g_aCurPos = WinGetPos($hGUI)
AdlibRegister("_Update_Timer", 990)

While 1
	Sleep(1000)
	If $g_iRemain = 0 Then ExitLoop
	_GuiPosWriteReg()
WEnd

AdlibUnRegister("_Update_Timer")
SoundSetWaveVolume(100)
SoundPlay(@WindowsDir & "\Media\tada.wav")

Global $g_bRed = True
AdlibRegister("_Red")

Local $iMousePos = MouseGetPos(1)
While 1
	Sleep(1000)
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

Func _Update_Timer()
	$g_iRemain = $g_iMSec - TimerDiff($g_iInit)
	If $g_iRemain <= 0 Then $g_iRemain = 0
	GUICtrlSetData($hSEC, _Dauer($g_iRemain))
EndFunc

Func _Dauer($iTime)
	Local $sDauergesamt = StringFormat("%.2d:%.2d:%.2d", (Floor($iTime / 3600000)), (Floor(Mod($iTime,3600000) / 60000)), (Mod(Mod($iTime,3600000),60000) / 1000)); umgerechnet in hh:mm:ss
	Return $sDauergesamt
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
Func _GuiPosReadReg() ; nötig für _GuiPos...
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

Func _GuiPosWriteReg() ; nötig für _GuiPos...
	Local $aTempPos = WinGetPos($hGUI)
	If $g_iCountMon = 1 Then
		If $aTempPos[0] <> $g_aCurPos[0] Then RegWrite("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosX", "REG_DWORD", $aTempPos[0])
		If $aTempPos[1] <> $g_aCurPos[1] Then RegWrite("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosY", "REG_DWORD", $aTempPos[1])
	Else
		If $aTempPos[0] <> $g_aCurPos[0] Then RegWrite("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosX_2", "REG_DWORD", $aTempPos[0])
		If $aTempPos[1] <> $g_aCurPos[1] Then RegWrite("HKEY_CURRENT_USER\Software\" & @ScriptName, "PosY_2", "REG_DWORD", $aTempPos[1])
	EndIf
EndFunc

Func _CountMon() ; nötig für _GuiPos...
	Return _WinAPI_GetSystemMetrics(80) ; 80 in Klammern steht für SM_CMONITORS - visible Monitors in MSDN Library
EndFunc
#endregion - _GuiPos...
#endregion - Funcs