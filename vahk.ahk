;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; vahk - use vi key maps for OS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#NoEnv ;adding the line #NoEnv anywhere in the script improves DllCall's performance when unquoted parameter types are used (e.g. int vs. "int").
#SingleInstance Force ; only one instance of the script is allowed to run
#WinActivateForce     ; forcfully activates window
#UseHook Off          ; Hotkeys will be implemented by the default method
SetBatchLines -1      ; script never sleeps (affects cpu utilization)
ListLines Off         ; omits subsequently executed lines from history
SendMode Input        ; best setting for send command

; if script is running as an .exe and the icon file exists; set tray icon
If( !A_IsCompiled && FileExist(A_ScriptDir . "\vahk.ico")) {
	Menu, Tray, Icon, %A_ScriptDir%\vahk.ico
}

; create tray <right-click> menu
Menu, Tray, NoStandard
Menu, Tray, Add, &Disable Hotkeys, DisableHotkeys
Menu, tray, add ; separator
Menu, tray, add, &Reload This Script, MyReload
Menu, tray, add, ListHotkeys Debug, MyListHotkeys
;Menu, tray, add, &Edit This Script, MyEdit
Menu, tray, add ; separator
Menu, Tray, Add, &Exit, QuitScript

Hotkey, f9, MyReload

;array := {"6": "j", "+6": "jj", "9": "k", "^9": "kk"}
;For key, value in array
	;Hotkey, %key%, newsend

Disabled := 0
mode := 0 
toggle_vi_mode()

;doesn't work mapping multiple keys
nmap("^q","jj{left}{left}")


Return ;end of auto-execute
;---------------------------------------------------------------
; Tray custom right click menu functions
;---------------------------------------------------------------

DisableHotkeys:
	If(Disabled) {
		Suspend, Off
		Disabled := 0
		Menu, Tray, Uncheck, &Disable Hotkeys
	} Else {
		Suspend, On
		Disabled := 1
		Menu, Tray, Check, &Disable Hotkeys
	}
Return

QuitScript:
	ExitApp
Return

*#v::toggle_vi_mode()

;#if ((IfWinActive, ahk_class Vim) || (IfWinActive, ahk_class mintty) && (vi_keys))
~Alt up::
	sleep 40
	if ((WinActive("ahk_class Vim") || WinActive("ahk_class mintty")) && (vi_keys))
		toggle_vi_mode()
	return


;---------------------------------------------------------------
ActivateTaskbarItem(n) {
	hwnd := TaskbarItem%n%
	If(hwnd) {
		If(DllCall("IsIconic", UInt, hwnd)) { ;METHOD 1a, check if minimized
			DllCall("ShowWindow", UInt, hwnd, UInt, 9) ;METHOD 1b, 9=SW_RESTORE
		}
		DllCall("SetForegroundWindow", UInt, hwnd) ;METHOD 1c
	}
}

;---------------------------------------------------------------
ReadWindowsOnTaskbar:
	ActiveTaskbarItem=
	if(!pidTaskbar) {
		WinGet,	pidTaskbar, PID, ahk_class Shell_TrayWnd
	}
	hProc := DllCall("OpenProcess", UInt, 0x38, Int, 0, UInt, pidTaskbar)
	pProc := DllCall("VirtualAllocEx", UInt, hProc, UInt, 0, UInt, 32, UInt, 0x1000, UInt, 0x4)
	if(!idxTB) {
		idxTB := GetTaskSwBar()
	}
	SendMessage, 0x418, 0, 0, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_BUTTONCOUNT
	buttonCount := ErrorLevel

	TaskbarItemCount := 1
	Loop, %buttonCount%	{
		SendMessage, 0x417, A_Index-1, pProc, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_GETBUTTON
		VarSetCapacity(btn, 32, 0)
		DllCall("ReadProcessMemory", UInt, hProc, UInt, pProc, UInt, &btn, UInt, 20, UInt, 0)
		idn	:= NumGet(btn, 4)
		fsState := NumGet(btn, 8, "uchar")
		;fsStyle := NumGet(btn, 9, "uchar")
		dwData := NumGet(btn, 12)
		DllCall("ReadProcessMemory", UInt, hProc, UInt, dwData, Int64P, hWnd:=0, UInt, dwData ? 4:8, UInt, 0)
		If(hWnd) {
			If(fsState&1) { ; Checks for TBSTATE_CHECKED in fsState in TB_GETBUTTON
				ActiveTaskbarItem := TaskbarItemCount
			}
			TaskbarItem%TaskbarItemCount% := hWnd
			GetTaskbarButtonTopLeft(idn, x, y)
			SetButtonTopLeftLoc(TaskbarItemCount, x, y)
			TaskbarItemCount++
		}
	}
	TaskbarItemCount--
Return


;---------------------------------------------------------------
GetTaskSwBar()
{
	ControlGet, hParent, hWnd,, MSTaskSwWClass1 , ahk_class Shell_TrayWnd
	ControlGet, hChild , hWnd,, ToolbarWindow321, ahk_id %hParent%
	Loop
	{
		ControlGet, hWnd, hWnd,, ToolbarWindow32%A_Index%, ahk_class Shell_TrayWnd
		If Not hWnd
			Break
		Else If hWnd = %hChild%
		{
			idxTB := A_Index
			Break
		}
	}
	Return idxTB
}

;---------------------------------------------------------------
GetTaskbarButtonTopLeft(id, ByRef x, ByRef y)
{
	global idxTB, pidTaskbar
	if(!idxTB) {
		idxTB := GetTaskSwBar()
	}
	if(!pidTaskbar) {
		WinGet,	pidTaskbar, PID, ahk_class Shell_TrayWnd
	}
	hProc := DllCall("OpenProcess", UInt, 0x38, Int, 0, UInt, pidTaskbar)
	pProc := DllCall("VirtualAllocEx", UInt, hProc, UInt, 0, UInt, 32, UInt, 0x1000, UInt, 0x4)
	;idxTB := GetTaskSwBar()	; dont think this is needed again

    SendMessage, 0x433, id, pProc, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_GETRECT
	;IfEqual, ErrorLevel, 0, return "Err: can't get rect"

	VarSetCapacity(rect, 32, 0)
	DllCall("ReadProcessMemory", UInt, hProc, UInt, pProc, UInt, &rect, UInt, 32, UInt, 0)

	DllCall("VirtualFreeEx", UInt, hProc, UInt, pProc, UInt, 0, UInt, 0x8000)
	DllCall("CloseHandle", UInt, hProc)

	ControlGet, hWnd, hWnd,, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd
	WinGetPos, x, y, w, h, ahk_id %hWnd%

	left := NumGet(rect, 0)
	top := NumGet(rect, 4)
	right := NumGet(rect, 8)
	bottom := NumGet(rect, 12)

	x := x + left
	y := y + top
}

;---------------------------------------------------------------
SetButtonTopLeftLoc(gi, x, y)
{
	global
	g_xs%gi% := x
	g_ys%gi% := y
}


;---------------------------------------------------------------
MyReload:
    Reload
Return

MyListHotkeys:
	ListHotkeys
Return

;MyEdit:
;    Edit
;Return

nmap(in, arg*)
{
	;Hotkey, mode = "normal"
	Static funs := {}, args := {}
	funs[in] := Func("sendit"), args[in] := arg
	msgbox initial mapping of %in%
	Hotkey, %in%, nmysend
	return

nmysend:
	funs[A_ThisHotKey].(args[A_ThisHotkey]*)
	return
}

sendit(msg) {
	msgbox s nmap
    sendplay, %msg%
}

toggle_vi_mode()
{
	global
	If (!vi_keys)
	{
		IfWinNotExist, vi_status
			create_vi_status_bar()
		vi_keys := true
		mode := "normal"
		update_vi_status_bar("AEEE00")
	}
	else
	{
		vi_keys := false
		mode := 0
		update_vi_status_bar("242321")
	}
}

create_vi_status_bar()
{
	ypos := (A_ScreenHeight) - 120
	Gui, +AlwaysOnTop +Disabled -SysMenu +Owner +Border
	Gui,Show,X0 Y%ypos% w100 h100 NoActivate,vi_status
 	Gui,Add,Picture,x5 y5 w90 h90, %A_ScriptDir%\vahk3.png
	Gui, Color, 141413
	WinSet, Transparent, 230, vi_status
	Gui -Caption
}

update_vi_status_bar(clr)
{
	Gui, Color, %clr%
}

set_mode(md)
{
	global
	mode := md
	if(md="normal")
	{
		update_vi_status_bar("AEEE00")
	}
	else if(md="visual")
	{
		update_vi_status_bar("FFA724")
	}
	else if(md="insert")
	{
		update_vi_status_bar("005FFF")
	}
	else if(md="replace")
	{
		update_vi_status_bar("FF9EB8")
	}
	else
	{
		mode := 0
		update_vi_status_bar("242321")
	}
}

#if ((mode = "normal") or (mode = "visual"))
;Movement
	*0::Send,{Home}
	*$::Send,{End}
	*g::
		if (A_PriorHotkey <> "*g" or A_TimeSincePriorHotkey > 400)
		{
			KeyWait, g
			return
		} 
		Send,^{Home}
		return
	+g::Send,^{End}
	*h::Send,{Left}
	*l::Send,{Right}
	*k::Send,{Up}
	*j::Send,{Down}
	*w::
		if (A_PriorHotkey = "*i" and A_TimeSincePriorHotkey < 400)
			Send,{shift up}^{left}{shift down}
		Send,^{right}
		return
	b::Send,^{left}
	*{::
		if (!GetKeyState("Control","P"))
		{
			Send,^{up}
			return
		}
		GoSub, ESCAPE
		return
	*}::Send,^{down}
	*^f::Send,{PgDn}
	*^b::Send,{PgUp}
	+f::
		premode=%mode%
		mode:="insert"
		;update_vi_status_bar("005FFF")
		input,fd,L1 I *,,*
		Send,^f
		sleep, 40
		sendplay,{%fd%}{enter}+{tab}{enter}{esc}{left}
		mode = %premode%
		update_vi_status_bar("AEEE00")
		return
	f::
		premode=%mode%
		mode:="insert"
		;update_vi_status_bar("005FFF")
		input,fd,L1 I *,,*
		Send,^f
		sleep, 40
		sendplay,{%fd%}{enter}{esc}{right}
		mode = %premode%
		;mode := "normal"
		update_vi_status_bar("AEEE00")
		return
	t::
		premode=%mode%
		mode:="insert"
		;update_vi_status_bar("005FFF")
		input,fd,L1 I *,,*
		Send,^f
		sleep, 40
		sendplay,{%fd%}{enter}{esc}{left}
		mode = %premode%
		;mode := "normal"
		update_vi_status_bar("AEEE00")
		return
	+.::
		if (A_PriorHotkey = "+." and A_TimeSincePriorHotkey < 400)
			Send,{tab}
		return
	+,::
		if (A_PriorHotkey = "+," and A_TimeSincePriorHotkey < 400)
			Send,+{tab}
		return

; copy paste
	*x::send,{shift up}{del}
	+x::send,{shift up}{backspace}
	*d::
		if (GetKeyState("Shift","P"))
			Send,{shift down}{end}
		else if (A_PriorHotkey = "*d" and A_TimeSincePriorHotkey < 400)
			Send,{home}{shift down}{end}
		Send,{shift up}^x
		GoSub, ESCAPE
		return
	*p::
		Send,{shift up}^v
		GoSub, ESCAPE
		return
	*y::
		Send,{shift up}^c
		GoSub, ESCAPE
		return

#if (mode = "normal")
	m::
		premode=%mode%
		mode:="insert"
		;update_vi_status_bar("005FFF")
		input,fd,L1 I *,,*
		Send,^+{f5}
		sleep, 40
		sendplay,{%fd%}!a
		mode = %premode%
		;mode := "normal"
		update_vi_status_bar("AEEE00")
		return
	`;::
		premode=%mode%
		mode:="insert"
		;update_vi_status_bar("005FFF")
		input,fd,L1 I *,,*
		Send,^+{f5}
		sleep, 40
		sendplay,{%fd%}!g{Enter}
		mode = %premode%
		;mode := "normal"
		update_vi_status_bar("AEEE00")
		return
	?::
		premode=%mode%
		mode:=0
		first:=TRUE
		;update_vi_status_bar("005FFF")
		loop {
			input,fd,L1 I *,,*
			if (fd = "[")
				break
			Send,^h
			sleep, 50
			Send,!d
			sleep, 50
			if (first) {
				send,{del}
				first:=FALSE
			}
			Sendplay, {right}{%fd%}{Enter}
			sleep, 50
			Sendplay, {esc}
			sleep, 50
			Sendplay, ^{PgUp}
		}
		mode = %premode%
		;mode := "normal"
		update_vi_status_bar("AEEE00")
		return
	;^o::send,+{f5}
	^i::send,+{f5 3}
	*o::
		if (GetKeyState("Shift","P"))
			Send,{home}{Enter}{up}
		else
			Send,{end}{Enter}
		;mode:="insert"
		;update_vi_status_bar("005FFF")
		set_mode("insert")
		return
	i::
		if (A_PriorHotkey = "y" and A_TimeSincePriorHotkey < 400)
		{
			msgbox copy word
			Send,^{left}{shift down}
			return
		}
		if (A_PriorHotkey = "d" and A_TimeSincePriorHotkey < 400)
		{
			msgbox cut word
			Send,^{left}{shift down}
			return
		}
		else if (A_PriorHotkey = "c" and A_TimeSincePriorHotkey > 400)
		{
			msgbox insert over word
			Send,^{left}{shift down}
			return
		}
		;mode:="insert"
		;update_vi_status_bar("005FFF")
		set_mode("insert")
		return
	+i::
		send,{home}
		;mode:="insert"
		;update_vi_status_bar("005FFF")
		set_mode("insert")
		return
	+a::
		send,{end}
		;mode:="insert"
		;update_vi_status_bar("005FFF")
		set_mode("insert")
		return
	a::
		send, {right}
		;mode:="insert"
		;update_vi_status_bar("005FFF")
		set_mode("insert")
		return
	+r::
		;mode:="replace"
		;update_vi_status_bar("FF9EB8")
		set_mode("replace")
		Send,{Insert}
		return
	v::
		;mode:="visual"
		;update_vi_status_bar("FFA724")
		set_mode("visual")
		Send,{shift down}
		return
	u::Send,{ctrl down}z{ctrl up}
	^r::Send,{ctrl down}y{ctrl up}
	^[:: Send,{Esc}
	+/::
	/::
		Send,^f
		mode:="insert"
		update_vi_status_bar("005FFF")
		return
	+8::send ^{right}{shift down}^{left}{shift up}^c^f^v{left}{enter 2}
	+3::send ^{right}{shift down}^{left}{shift up}^c^f^v{left}{enter}+{tab}{enter}
	; Switch to previous Z-order window
	*;::
		if (A_PriorHotkey <> "*;" or A_TimeSincePriorHotkey > 400)
		{
			KeyWait, `;
			return
		} 
		curActiveHwnd := DllCall("GetForegroundWindow")
		hwnd := curActiveHwnd
		Loop {
			hwnd := DllCall("GetWindow", UInt, hwnd, UInt, 2) ; 2 = GW_HWNDNEXT
			If(DllCall("IsWindowVisible", UInt, hwnd)) {
				Break
			;} Else {
			;	Tooltip, Next window wasn't visible
			}
		}
		DllCall("SetForegroundWindow", UInt, hwnd) ;METHOD 2c
		If(DllCall("IsIconic", UInt, hwnd)) { ;METHOD 2c, check if minimized
			DllCall("ShowWindow", UInt, hwnd, UInt, 9) ;METHOD 2b, 9=SW_RESTORE
		}
		Return

	; Go to previous item on task bar
	*^h::
		Gosub, ReadWindowsOnTaskbar
		If(ActiveTaskbarItem) {
			ItemPrev := ActiveTaskbarItem - 1
			If(ItemPrev < 1) {
				ItemPrev := TaskbarItemCount
			}
		} Else {	;If currently on a window without a taskbar entry - go to first item
			ItemPrev := 1
		}
		ActivateTaskbarItem(ItemPrev)
		Return

	; Go to next item on task bar
	*^l::
		Gosub, ReadWindowsOnTaskbar
		If(ActiveTaskbarItem) {
			ItemNext := ActiveTaskbarItem+1
			If(ItemNext > TaskbarItemCount) {
				ItemNext := 1
			}
		} Else {	;If currently on a window without a taskbar entry - go to first item
			ItemNext := 1
		}
		ActivateTaskbarItem(ItemNext)
		Return




#if ((mode = "insert") or (mode = "visual") or (mode = "replace"))
	*[::
		if ((mode = "visual") && GetKeyState("Control","P"))
		{
			send,{shift up}
		}
		if (mode = "replace")
			send,{Insert}
		mode := "normal"
		update_vi_status_bar("AEEE00")
		return
	;^\::
		;if (mode = "visual")
		;{
			;if GetKeyState("Shift","D")
			;{
				;Send,{shift up}
				;return
			;}
			;send,{left}
			;mode = "normal"
			;return
		;}
		;else if (mode = "insert")
			;mode = "normal"
;}
;If ; end of #If

#if (mode = "visual")
	*i::return

;#if
#if

ESCAPE:
	if ((mode = "visual") && GetKeyState("Control","P"))
	{
		send,{shift up}
	}
	if (mode = "replace")
		send,{Insert}
	mode := "normal"
	update_vi_status_bar("AEEE00")
return

