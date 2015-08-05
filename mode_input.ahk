#NoEnv ;adding the line #NoEnv anywhere in the script improves DllCall's performance when unquoted parameter types are used (e.g. int vs. "int").
#SingleInstance Force ; only one instance of the script is allowed to run
#WinActivateForce     ; forcfully activates window
#UseHook Off          ; Hotkeys will be implemented by the default method
SetBatchLines -1      ; script never sleeps (affects cpu utilization)
;setkeydelay, -1
ListLines Off         ; omits subsequently executed lines from history
SendMode Input        ; best setting for send command

;setwindelay, 0 


N := 0x01 ; normal  mode  0b0000 0001
I := 0x02 ; insert  mode  0b0000 0010
V := 0x04 ; visual  mode  0b0000 0100
R := 0x08 ; replace mode  0b0000 1000
C := 0x10 ; command mode  0b0001 0000
L := 0x20 ; list    mode  0b0010 0000
F := 0x40 ; find    mode  0b0100 0000

create_vi_status_bar()
set_mode(N)
keystream := ""
maps := []
X := 1
vi_on := true
vi_status := ""
leader := ","

transform, etr, chr, 10 ; store ascii value for enter to variable
transform, ex, chr, 27 ; store ascii value for escape to variable
transform, spc, chr, 0x20 ; store ascii value for space to variable
transform, dollar, chr, 36 ; store ascii value for dollar symbol to variable
transform, tilde, chr, 126 ; store ascii value for tilde to variable

map(dlr,":normalize()",N|I|R|V|L)
;test("hello")
;msgbox % A_IsUnicode ? "Unicode" : "ANSI"
;ts := "z"
;transform, varin, chr, 3
;transform, var, asc, varin
;msgbox % "Ascii value for space is " . spc . " or " . chr(32)

map(tilde,":swap_case()",N)

map("q",":close()",C)
map(":",":set_mode(C)",N)
map("<C-q>",":toggle_vi()",N)

; set modes
map("a","{right};:set_mode(I)",N)
map("A","{end};:set_mode(I)",N)
map("r",":set_mode(R);:get_chr();:set_mode(N)",N)
map("R",":set_mode(R)",N)
map("v",":set_mode(V)",N)
map("V","{home}+{end};:set_mode(V)",N)
map("i",":set_mode(I)",N)
map("I","{home};:set_mode(I)",N)
map("cc","{home}+{end}^x;:set_mode(I)",N)
map("ciw",":get_word();^x;:set_mode(I)",N)
map("C","+{end}^x;:set_mode(I)",N|V)
map("o","{end}{enter};:set_mode(I)",N)
map("O","{home}{enter}{up};:set_mode(I)",N)
map("/","^f;:set_mode(F)",N)
map("?","^f;:set_mode(F)",N)

; motion
map("h",":move(""left"")",N|V)
map("j",":move(""down"")",N|V)
map("k",":move(""up"")",N|V)
map("l",":move(""right"")",N|V)
map("<C-h>","^!{home}{enter};^{pgup 2}",N|V)
map("<C-l>","^!{home}{enter}",N|V)
map("<C-f>",":move(""PgDn"")",N|V)
map("<C-b>",":move(""PgUp"")",N|V)
map("gg",":move(""top"")",N|V)
map("G",":move(""bottom"")",N|V)
map("0",":move(""home"")",N|V)
;map(dollar,":move(""end"")",N|V) ; XXX seems to be an issue
map("w",":move(""next"")",N|V)
map("b",":move(""front"")",N|V)
map("e",":move(""last"")",N|V)
map("{",":move(""para_up"")",N|V)
map("}",":move(""para_down"")",N|V)
map("jj",":set_mode(N);:move(""down"")",I)
map("kk",":set_mode(N);:move(""up"")",I)
map("jk",":set_mode(N)",I)
map("kj",":set_mode(N)",I)
;map("n","^{PgDn}",N)
;map("N","^{PgUp}",N)
map("N","^!{home}{enter};{up}{left 4};^{pgup 2}",N|V)
map("n","^!{home}{enter};{up}{left 4}",N|V)
map("zt",":click",N)

; copy/paste/etc
map("x","{del}",N|V)
map("X","{backspace}",N)
map("p","{right}^v",N)
map("P","^v",N|V)
map("y","^c{left};:set_mode(N)",V)
map("yw","+^{right}^c{left};:set_mode(N)",N)
;map("yiw","^{left}+^{right}^c{left};:set_mode(N)",N)
map("yiw",":get_word();^c{left};:set_mode(N)",N)
map("yy","{home}+{end}^c",N)
map("Y","{home}+{end}^c",N)
map("d","^x;:set_mode(N)",V)
map("dd","{home}+{end}^x",N)
map("D","+{end}^x",N)
;map("iw","^{left}+^{right}",V)
map("iw",":get_word()",V)
map("<C-w>",":get_word()",N)
map("<C-s>",":word_beg()",N)
map("<C-d>",":word_end()",N)
map("<C-a>",":caret_pos()",N)

; misc
map(">>","{tab}",N|V)
map("<<","+{tab}",N|V)
map("<C-o>","+{f5}",N)
map("<C-i>","+{f5 3}",N)
map("u","^z",N)
map("<C-r>","^y",N)

; window manipulation
map("<leader>ww",":win_swap_mon()",N|I|R|V)
map("<leader>wo",":win_max()",N|I|R|V)
map("<leader>wH",":win_min()",N|I|R|V)
map("<leader>wh",":win_move(""left"")",N|I|R|V)
map("<leader>wj",":win_move(""down"")",N|I|R|V)
map("<leader>wk",":win_move(""up"")",N|I|R|V)
map("<leader>wl",":win_move(""right"")",N|I|R|V)
map("<leader>wn",":win_cycle(""next"")",N|I|R|V)
map("<leader>wp",":win_cycle(""prev"")",N|I|R|V)
;map("<leader>wq",":win_cycle(""last"")",N|I|R|V)
map("<leader>w;","!{tab}",N|I|R|V)

; in work
map("<leader>bl",":set_mode(L)",N)
map("h","+{tab}",L)
map("l","{tab}",L)
map(etr,"{alt up};:set_mode(N)",L)
map(ex,":normalize()",I|R|V|L)
map(ex,"{esc}",N)
map(ex,"{esc};:set_mode(N)",F)
map(etr,"{enter};{esc};:set_mode(N);^h!d!r{enter}{tab 3}{enter}",F)
;map(etr,"{enter};{esc};:set_mode(N);^H;!d;!R;!H",F)
;map("<C-s>","^h;!d;!r;{enter};{tab 3};{enter}",N)
;map("<C-s>","^h!d!r!c;{tab 3}{enter}",N)
;map("<leader>" . spc,"^h!d!r{down}{enter};{tab 3}{enter}",N)
;map("<leader><32>","^h!d!r{down}{enter};{tab 3}{enter}",N)
map("<leader>" . etr,"{enter}",N)
map(etr,":move(""down"");:move(""home"")",N)

;for i, val in maps
;{
	;msgbox % i " => in:" . val.in . " out:" . val.arg . " mode:" . val.md . " fcn:" . val.fcn
;}

gosub, forever
return

forever:
loop
{
	; if vi is toggled off then break the loop
	if (!vi_on)
		break
	;input,strk,L1 I,,{esc}{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{BS}
	else if (writable)
		input,strk,L1 I M V T2,,
	else
		input,strk,L1 I M,,!{tab},{LAlt}{tab},{tab},{space}
	
	;msgbox % "keyhit " . asc(strk)
	if (strk = 0x20)
		msgbox "space was hit"

	if (ErrorLevel = "Timeout")
	{
		if (strlen(keystream))
			status_bar_blink()
		keystream := ""
		continue
	}
	else if (ErrorLevel = "Match")
	{
		msgbox % "match of " . strk
		send %strk%
		continue
	}
	;var := Asc(strk)
	;msgbox % "key was " . strk . " ascii code was " . var
	;continue

	;if (GetKeyState("Shift",U) & regexmatch(strk,"[A-Z]",uc))
		;stringlower strk, strk

	; may need to convert everything to ascii codes to allow for special characters
	keystream .= strk
	rtn := check_for_matches(keystream)
	;msgbox % "matched [" . rtn.count . "]"
	if (rtn.exact_match)
	{
		if (writable)
		{
			pos := 1
			while pos := regexmatch(keystream,"[a-zA-Z0-9_]",m,pos+strlen(m))
				send {backspace}
		}
		sendit(rtn.data[1].out)
		keystream := ""
	}
	else if (rtn.count = 0)
	{
		; invalid keystream
		if (!writable)
			status_bar_blink()
		;else
			;send %keystream%
		keystream := ""
		;msgbox % "invalid keystream:" . keystream
		;exitapp
	}
	else
	{
		; one or more matches but none are complete
		; display current keystream
	}
}

^q::
toggle_vi()
return

test()
{
	send {tab}
	;msgbox "this fcn was called"
}
normalize()
{
	global
	send {alt up}
	set_mode(N)
	X = 1
	keystream :=""
}

get_word()
{
	o_clip := ClipboardAll
	send {f8 2}^c
	sleep 80
	if (regexmatch(clipboard," "))
		send +{left}
	clipboard = %o_clip%
}
get_word_slow()
{
	o_clip := ClipboardAll

	send +^{left}+{left} ; move a word +1 to the left
	send ^c
	clipwait, 1
	;sleep 50
	;sel := clipboard
	;sleep 50
	;if (regexmatch(sel,"\w",mtc))
	while regexmatch(clipboard,"P)\w+$",mtc)
	{
		;msgbox % "loop1 match in sel[" . sel . "][" . strlen(sel) . "] is [" . mtc . "]"
		if (mtc != strlen(sel))
			break
		send +^{left}+{left} ; move a word +1 to the left
		sleep 50
		send ^c
		clipwait, 1
		;sleep 50
		;sel := clipboard
		;sleep 50
	}
	send {right}{left %mtc%}
	sleep 50
	send +{right %mtc%}+^{right}+{right}
	sleep 50
	send ^c
	clipwait, 1
	;sleep 50
	;sel := clipboard
	;sleep 50
	;msgbox % "sel = " . sel
	while regexmatch(clipboard,"P)^\w+",mtc)
	{
		;msgbox % "loop2 match in sel[" . sel . "][" . strlen(sel) . "] is [" . mtc . "]"
		if (mtc != strlen(sel))
			break
		send +^{right}+{right} ; move a word +1 to the left
		sleep 50
		send ^c
		sleep 50
		;sel := clipboard
		;sleep 50
	}
	send {left}+{right %mtc%}


	clipboard = %o_clip%
}
word_beg()
{
	o_clip := ClipboardAll
	send +{home}
	send ^c
	sleep 50
	regexmatch(clipboard,"P)\w+[ ]*.$",pos)
	send {right}{left %pos%}
	clipboard = %o_clip%
}
word_end()
{
	o_clip := ClipboardAll
	forward:
	send +{end}
	send ^c
	sleep 50
	;regexmatch(clipboard,"P)^.[ ]*\w+",pos)

	regexmatch(clipboard,"P)[ `t`n`r`.]*\w+",pos)
	if (!pos)
	{
		;send ^{right}
		send {right}
		gosub forward
	}
	send {left}{right %pos%}
	clipboard = %o_clip%
	return
}
swap_case()
{
	o_clip := ClipboardAll

	send +{right}^c
	sleep 20
	sel := clipboard
	if (regexmatch(sel,"^[a-z]$",lower))
	{
		stringupper new, lower
		send %new%{left}{right}
	}
	else if (regexmatch(sel,"^[A-Z]$",upper))
	{
		stringlower new, upper
		send %new%{left}{right}
	}
	else
		send {left}

	clipboard = %o_clip%
}

move(where)
{
	global
	keys_beg := (mode = V ? "{shift down}" : "")
	keys_end := (mode = V ? "{shift up}" : "")

	if (where = """left""")
		send %keys_beg%{left}%keys_end%
	else if (where = """right""")
		send %keys_beg%{right}%keys_end%
	else if (where = """down""")
		send %keys_beg%{down}%keys_end%
	else if (where = """up""")
		send %keys_beg%{up}%keys_end%
	else if (where = """PgUp""")
		send %keys_beg%{PgUp}%keys_end%
	else if (where = """PgDn""")
		send %keys_beg%{PgDn}%keys_end%
	else if (where = """top""")
		send %keys_beg%^{home}%keys_end%
	else if (where = """bottom""")
		send %keys_beg%^{end}%keys_end%
	else if (where = """home""")
		send %keys_beg%{home}%keys_end%
	else if (where = """end""")
		send %keys_beg%{end}%keys_end%
	else if (where = """next""")
		send %keys_beg%^{right}%keys_end%
	else if (where = """front""")
		send %keys_beg%^{left}%keys_end%
	else if (where = """para_up""")
		send %keys_beg%^{up}%keys_end%
	else if (where = """para_down""")
		send %keys_beg%^{down}%keys_end%
	else if (where = """last""")
	{
		o_clip := ClipboardAll

		send +{end}^c{left}
		sleep 20
		sel := clipboard
		non_word_pos := regexmatch(sel,"(?!\w)")
		;msgbox % "found end:" non_word_pos
		if (non_word_pos>1)
		{
			;msgbox % "found end:" non_word_pos
			mov := non_word_pos - 1
			send {right %mov%}
		}
		else
		{
			send ^{right}+{end}^c{left}
			sleep 20
			sel := clipboard
			non_word_pos := regexmatch(sel,"(?!\w)")
			;msgbox % "found end:" non_word_pos
			if (non_word_pos)
			{
				mov := non_word_pos - 1
				send {right %mov%}
			}
			else
				send {left}
		}

		clipboard = %o_clip%
	}
}

get_chr()
{
	input,strk,L1 I M V,,
}

close()
{
	exitapp
}

win_max()
{
	WinGet, WinID ,, A ; get active window id
	WinGet, max_state, MinMax, A ; get active window id
	if (max_state != 1)
		WinMaximize, ahk_id %WinId%
	else
		WinRestore, ahk_id %WinId%
}

win_min()
{
	WinGet, WinID ,, A ; get active window id
	WinGet, min_state, MinMax, A ; get active window id
	if (min_state != -1)
		WinMinimize, ahk_id %WinId%
	else
		WinRestore, ahk_id %WinId%
}

win_move(loc)
{
	WinGet, WinID ,, A ; get active window id

	WinGet, max_state, MinMax, A ; get active window id
	if (max_state = 1)
		WinRestore, ahk_id %WinId%

	WinGetPos, WinX, WinY, WinWidth, , ahk_id %WinID%
	WinCenter := WinX + (WinWidth / 2)

	SysGet, MonitorCount, MonitorCount
	Loop, %MonitorCount%
	{
		SysGet, Monitor, Monitor, %A_Index%

		if (WinCenter > MonitorLeft and WinCenter < MonitorRight)
		{
			X := MonitorLeft
			Y := MonitorTop
			W := MonitorRight - MonitorLeft
			H := MonitorBottom - MonitorTop
			break
		}
	}

	if (loc = """left""")
		W := W/2
	else if (loc = """up""")
		H := H/2
	else if (loc = """down""")
	{
		Y := Y + H/2
		H := H/2
	}
	else if (loc = """right""")
	{
		X := X + W/2
		W := W/2
	}

	WinMove, ahk_id %WinID%, , %X%, %Y%, %W%, %H%
	return
}


win_swap_mon() ; Swaps active window onto the other monitor
{
	WinGet, WinID ,, A ; get active window id
	SysGet, Mon1, Monitor, 1
	SysGet, Mon2, Monitor, 2
	WinGetPos, WinX, WinY, WinWidth, , ahk_id %WinID%

	WinCenter := WinX + (WinWidth / 2) ; Determines which monitor this is on by the position of the center pixel.
	if (WinCenter > Mon1Left and WinCenter < Mon1Right) {
		WinX := Mon2Left + (WinX - Mon1Left)
	} else if (WinCenter > Mon2Left and WinCenter < Mon2Right) {
		WinX := Mon1Left + (WinX - Mon2Left)
	}

	WinMove, ahk_id %WinID%, , %WinX%, %WinY%
	return
}

win_cycle(dir)
{
	if (dir = """last""")
	{
		msgbox "got in"
		curActiveHwnd := DllCall("GetForegroundWindow")
		hwnd := curActiveHwnd
		Loop 
		{
			hwnd := DllCall("GetWindow", UInt, hwnd, UInt, 2) ; 2 = GW_HWNDNEXT
			If(DllCall("IsWindowVisible", UInt, hwnd))
				Break
		}

		DllCall("SetForegroundWindow", UInt, hwnd) ;METHOD 2c

		If(DllCall("IsIconic", UInt, hwnd)) ; check if minimized
			DllCall("ShowWindow", UInt, hwnd, UInt, 9) ;METHOD 2b, 9=SW_RESTORE

		Return
	}
	else if (dir = """prev""")
	{
		;hwnd := WinActive("A")
		;;msgbox % "active:" . hwnd
		;Loop
		;{
			;hwnd := DllCall("GetWindow",uint,hwnd,uint,2) ; 2 = GW_HWNDNEXT
			;; GetWindow() returns a decimal value, so we have to convert it to hex
			;;msgbox % "next:" . hwnd . " var1:" . var1
			;SetFormat,integer,hex
			;hwnd += 0
			;SetFormat,integer,d
			;; GetWindow() processes even hidden windows, so we move down the z oder until the next visible window is found
			;if (DllCall("IsWindowVisible",uint,hwnd) = 1)
			;break
		;}
		;;msgbox % "call:" . hwnd
		;WinActivate,ahk_id %hwnd%
		send !+{tab}
		return
	}

	Gosub, ReadWindowsOnTaskbar
	If(ActiveTaskbarItem) 
	{
		if (dir = """prev""")
			Item := ActiveTaskbarItem - 1
		else if (dir = """next""")
			Item := ActiveTaskbarItem + 1

		if(Item < 1)
			Item := TaskbarItemCount
		else if(Item > TaskbarItemCount)
			Item := 1
	} 
	Else
	{	;If currently on a window without a taskbar entry - go to first item
		Item := 1
	}
	ActivateTaskbarItem(Item)
	Return
}

sendit(msg) {
	global
	stringsplit, cmd_array, msg, `;
	loop, %cmd_array0%
	{
		cmd := cmd_array%a_index%
		if regexmatch(cmd,"^:(?P<fcn>.*)\((?P<args>.*)\)",_)
		{
			;msgbox % "fcn:" . _fcn . " args:" . _args
			if (IsFunc(_fcn))
				if (regexmatch(_args,""""))
					%_fcn%(_args)
				else
					%_fcn%(%_args%)
			else
			{
				msgbox error with mapped function: `"%_fcn%`" is not a valid function name
				exitapp
			}
		}
		else
		{
			send, %cmd%
		}
		sleep 10
	}
}

map(in, out, md, fcn:="")
{
	global
	; replace leader tags with the leader string
	in := regexreplace(in,"i)<leader>",leader)

	; replace control tags with the anscii key
	while regexmatch(in, "i)<C-[a-z]>",str)
		in := regexreplace(in,str,ctrl(str))

	; replace control tags with the anscii key
	;while regexmatch(in, "<[0-9]+>",str)
		;in := regexreplace(in,str,ctrl(str))
	;in := regexreplace(in,"<([0-9]+)>",chr("$1"))
	in := regexreplace(in,"<([0-9]*)>",chr(32))
	;msgbox % "map -> in[" . in . "]"

	obj := {in:in, out:out, md:md}
	maps.insert(1,obj)
}
ctrl(blk)
{
	ltr := regexreplace(blk,"i)<C-([a-z])>","$L1")
	transform, code, asc, %ltr%
	transform, ctrl_key, chr, (code-96)
	return ctrl_key
}

check_for_matches(key_pressed)
{
	global
	obj := {count:0, exact_match:false, data:{}}
	for index, key_map in maps
	{
		if (key_map.md & mode)
		{
			needle = ^%key_pressed%
			if (RegExMatch(key_map.in,needle))
			{
				obj.count++
				obj.data[obj.count] := key_map
				if (key_pressed = key_map.in)
					obj.exact_match := true
			}
		}
	}
	if ((obj.exact_match) && (obj.count > 1))
	{
		errmsg := "keymap conflicts:"
		for each_one, rec in obj.data
		{
			errmsg .= "`n   [" . rec.in . "]"
		}
		msgbox % errmsg
		exitapp
	}
	return obj
}

show_msg(nt)
{
	msgbox % "you typed " . nt
}

create_vi_status_bar()
{
	global
	ypos := (A_ScreenHeight) - 120
	Gui, +AlwaysOnTop +Disabled -SysMenu +Owner +Border
	Gui,Show,X0 Y%ypos% w100 h100 NoActivate,vi_status
 	Gui,Add,Picture,x5 y5 w90 h90, %A_ScriptDir%\vahk3.png
	Gui, Color, 141413
	WinSet, Transparent, 230, vi_status
	Gui -Caption
}

toggle_vi()
{
	global
	if (vi_on = true)
	{
		WinSet, Transparent, 030, vi_status
		vi_on := false
	}
	else
	{
		WinSet, Transparent, 230, vi_status
		vi_on := true
		gosub, forever
	}
}

update_vi_status_bar(clr)
{
	Gui, Color, %clr%
}

status_bar_blink()
{
	global
	last_mode := mode

	set_mode(0)
	soundbeep ,40,20
	sleep 50
	set_mode(last_mode)
}

set_mode(md)
{
	global
	last_mode := mode
	mode := md
	if(md = N)
	{
		update_vi_status_bar("AEEE00")
		writable := false
		if (last_mode = R)
			send {insert}
	}
	else if(md = V)
	{
		update_vi_status_bar("FFA724")
		writable := false
	}
	else if(md = I)
	{
		update_vi_status_bar("005FFF")
		writable := true
	}
	else if(md = R)
	{
		update_vi_status_bar("FF9EB8")
		writable := true
		send {insert}
	}
	else if(md = C)
	{
		update_vi_status_bar("242321")
		writable := false
	}
	else if(md = L)
	{
		update_vi_status_bar("cF1E58")
		writable := false
		sleep 20
		send {alt down}{tab}
		sleep 20
		send +{tab}
		sleep 20
	}
	else if(md = F)
	{
		;update_vi_status_bar("FFFFFF")
		writable := true
	}
	;else if(md="quit")
	;{
		;msgbox % "commanded:" . md
		;exitapp
	;}
	else
	{
		mode := 0
		update_vi_status_bar("FFFFFF")
	}
}


; taskbar stuff
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
