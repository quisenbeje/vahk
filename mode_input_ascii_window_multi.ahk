#NoEnv ;adding the line #NoEnv anywhere in the script improves DllCall's performance when unquoted parameter types are used (e.g. int vs. "int").
#SingleInstance Force ; only one instance of the script is allowed to run
#WinActivateForce     ; forcfully activates window
#UseHook Off          ; Hotkeys will be implemented by the default method
SetBatchLines -1      ; script never sleeps (affects cpu utilization)
SetTitleMatchMode, 2
setkeydelay, -1
ListLines Off         ; omits subsequently executed lines from history
SendMode Input        ; best setting for send command
SetFormat,integer,d

;setwindelay, 0 


N := 0x01 ; normal  mode  0b0000 0001
I := 0x02 ; insert  mode  0b0000 0010
V := 0x04 ; visual  mode  0b0000 0100
R := 0x08 ; replace mode  0b0000 1000
C := 0x10 ; command mode  0b0001 0000
L := 0x20 ; list    mode  0b0010 0000
F := 0x40 ; find    mode  0b0100 0000
P := 0x80 ; prefix  mode  0b1000 0000

create_vi_status_bar()
last_mode := 0x01
set_mode(N)
keystream := ""
maps := {}
X := 0
vi_on := true
vi_status := ""
dir_bottom := true

transform, etr, chr, 10 ; store ascii value for enter to variable
transform, ex, chr, 27 ; store ascii value for escape to variable
transform, pre, chr, 29 ; store ascii value for ctrl+] to variable
transform, spc, chr, 0x20 ; store ascii value for space to variable


leader := ","
prefix := pre

; default keymaps to apply to all windows
win_type := ""
map("~",":swap_case()",N)

map("q",":close()",C)
;map("<C-q>",":toggle_vi()",N)

map("1",":multiple(1)",N)
map("2",":multiple(2)",N)
map("3",":multiple(3)",N)
map("4",":multiple(4)",N)
map("5",":multiple(5)",N)
map("6",":multiple(6)",N)
map("7",":multiple(7)",N)
map("8",":multiple(8)",N)
map("9",":multiple(9)",N)

; set modes
;map("v",":set_mode(N)",C)
;map("v",":toggle_vi2()",C)
map("<prefix>",":toggle_vi2()",C)
map("<prefix>",":set_mode(C)",P)
map("<prefix>",":set_mode(C)",N)
map("<leader>w",":set_mode(C)",N)
;map("qq",":set_mode(P)",N)
map(":",":set_mode(C)",N)
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

map("n",":look(""forward"")",N)
map("N",":look(""backward"")",N)
map("/","^f;:set_mode(F);:set_dir(""bottom"")",N)
map("?","^f;:set_mode(F);:set_dir(""top"")",N)
map("f","^f;:get_chr();{enter}{esc}{left};:set_dir(""bottom"")",N)
map("F","^f;:get_chr();{enter}{esc};:set_dir(""top"");:look(""forward"");{left}",N)
map("t","^f;:get_chr();{enter}{esc}{left 2};:set_dir(""bottom"")",N)
map("T","^f;:get_chr();{enter}{esc};:set_dir(""top"");:look(""forward"");{right}",N)
map("*",":get_word();^f;{enter}{esc};:set_dir(""bottom"");:look(""forward"")",N)
map("#",":get_word();^f;{enter}{esc};:set_dir(""top"");:look(""forward"")",N)


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
map("<C-s>",":word_beg()",N)
map("<C-d>",":word_end()",N)

; misc
map(">>","{tab}",N|V)
map("<<","+{tab}",N|V)
map("<C-o>","+{f5}",N)
map("<C-i>","+{f5 3}",N)
map("u","^z",N)
map("<C-r>","^y",N)

; window manipulation
map("w",":win_swap_mon()",C)
map("o",":win_max()",C)
map("H",":win_min()",C)
map("h",":win_move(""left"")",C)
map("j",":win_move(""down"")",C)
map("k",":win_move(""up"")",C)
map("l",":win_move(""right"")",C)
map("n",":win_cycle(""next"")",C)
map("p",":win_cycle(""prev"")",C)
;map("q",":win_cycle(""last"")",C)
map(";","!{tab}",C)
map("d","!{f4}",C)

win_type := "Microsoft Word"
;map("j",":win_move(""up"")",N)
;map("k",":win_move(""down"")",C)
win_type := ""

; in work
map("<leader>bl",":set_mode(L)",N)
map("b",":set_mode(L)",C)
map("h","+{tab}",L)
map("l","{tab}",L)
map(etr,"{alt up};:set_mode(N)",L)
map(ex,":normalize()",I|R|V)
map(ex,":set_mode(last_mode)",C|L)
map(ex,"{esc}",N)
map(ex,"{esc};:set_mode(N)",F)
map(etr,"{enter};{esc};:set_mode(N);^h!d!r{enter}{tab 3}{enter}",F)
;map(etr,"{enter};{esc};:set_mode(N);^H;!d;!R;!H",F)
;map("<C-s>","^h;!d;!r;{enter};{tab 3};{enter}",N)
;map("<C-s>","^h!d!r!c;{tab 3}{enter}",N)
map("<leader>" . spc,"^h!d!r{down}{enter};{tab 3}{enter}",N)
;map("<leader><32>","^h!d!r{down}{enter};{tab 3}{enter}",N)
map("<leader>" . etr,"{enter}",N)
map(etr,":move(""down"");:move(""home"")",N)

; motion
map("<C-h>","^!{home}{enter};^{pgup 2}",N|V)
map("<C-l>","^!{home}{enter}",N|V)
map("<C-f>",":move(""PgDn"")",N|V)
map("<C-b>",":move(""PgUp"")",N|V)
map("gg",":move(""top"")",N|V)
map("G",":move(""bottom"")",N|V)
map("0",":move(""home"")",N|V)
map("$",":move(""end"")",N|V)
map("w",":move(""next"")",N|V)
map("b",":move(""front"")",N|V)
map("e",":move(""last"")",N|V)
map("{",":move(""para_up"")",N|V)
map("}",":move(""para_down"")",N|V)
map("jj",":set_mode(N);:move(""down"")",I)
map("kk",":set_mode(N);:move(""up"")",I)
map("jk",":set_mode(N)",I)
map("kj",":set_mode(N)",I)
;map("N","^!{home}{enter};{up}{left 4};^{pgup 2}",N|V)
;map("n","^!{home}{enter};{up}{left 4}",N|V)
map("zt",":scroll(""down"")",N)
map("zb",":scroll(""up"")",N)
map("h",":move(""left"")",N|V)
map("j",":move(""down"")",N|V)
map("k",":move(""up"")",N|V)
map("l",":move(""right"")",N|V)
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
		input,strk,L1 I M V T2,^{{},
		;input,strk,L1 I M V T2,,
	else
		input,strk,L1 I M,,{tab},{LAlt}{tab},{tab},{space}
	
	;msgbox % "keyhit " . asc(strk)
	;gosub forever

	if (ErrorLevel = "Timeout")
	{
		if (strlen(keystream))
			status_bar_blink()
		keystream := ""
		;continue
		gosub forever
	}
	else if (ErrorLevel = "Match")
	{
		msgbox % "match of " . strk
		send %strk%
		continue
	}

	; may need to convert everything to ascii codes to allow for special characters
	transform, s_code, asc, %strk%
	;if (writable && s_code = 27)
		;send % ex
	;else if (writable)
		;send % strk


	keystream .= s_code . ";"
	ndx := (mode + 0) . ";" . keystream
	; look mappings of the keystream for all window types
	for wt, km in maps[ndx]
	{
		; check if active window is one of the wintypes
		IfWinActive, %wt%, %wt%
		{
			tooltip % "keymap (" . km . ") found for: " . wt
			; if so then send, clear keystream, and call gosub forever
			if (km != "")
			{
				sendit(km)
				keystream := ""
				gosub forever
			}
		}
	}
	; if here check for default wintype
	if (maps[ndx,""] != "")
	{
		tooltip % "default keymap (" . km . ") found"
		sendit(maps[ndx,""])
		keystream := ""
		gosub forever
	}
	; no direct match. check for parial
	else
	{
		for index, ele in maps
		{
			for wt, km in ele
			{
				; go back to input to get next keystroke
				if ((wt = "" || or winactive(wt)) && regexmatch(index,"^" . ndx))
				{
					tooltip % "partial keymap (" . index . ") found for win:" . wt
					gosub forever
				}
			}
		}

		; no possible key map match
		if (!writable)
		{
			tooltip "no match found"
			status_bar_blink()
		}
	}
	keystream := ""
}

;^q::
;toggle_vi()
;return

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
	X = 0
	keystream :=""
}

multiple(num)
{
	global
	X := X*10 + num
	;msgbox % "num:" . num . " X:" . X
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

	if (X = 0)
		X := 1

	if (where = """left""")
		send %keys_beg%{left %X%}%keys_end%
	else if (where = """right""")
		send %keys_beg%{right %X%}%keys_end%
	else if (where = """down""")
		send %keys_beg%{down %X%}%keys_end%
	else if (where = """up""")
		send %keys_beg%{up %X%}%keys_end%
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
		send %keys_beg%{ctrl down}{right %X%}{ctrl up}%keys_end%
	else if (where = """front""")
		send %keys_beg%{ctrl down}{left %X%}{ctrl up}%keys_end%
	else if (where = """para_up""")
		send %keys_beg%{ctrl down}{up %X%}{ctrl up}%keys_end%
	else if (where = """para_down""")
		send %keys_beg%{ctrl down}{down %X%}{ctrl up}%keys_end%
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

	X := 0
}

look(dir)
{
	global
	if (dir = """forward""")
		if (dir_bottom)
			send ^{PgDn}
		else
			send ^{PgUp}
	else if (dir = """backward""")
		if (dir_bottom)
			send ^{PgUp}
		else
			send ^{PgDn}
	else
		msgbox "bad argument to look()"

	;msgbox % "direction is bottom [" . dir_bottom "]"
}

set_dir(dir)
{
	global
	if (dir = """bottom""")
		dir_bottom := true
	else if (dir = """top""")
		dir_bottom := false
	else
		msgbox "bad argument to set_dir()"
	
	;msgbox % "direction is bottom [" . dir_bottom "]"
}

scroll(dir)
{
	;msgbox % "dir:" . dir . " tms:" . tms
	; in msword be sure to turn "smart scrolling" off in adv options
	loop 30
	{
		if (dir = """up""")
			click wheelup
		else if (dir = """down""")
			click wheeldown
	}
	send {right}{left}
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
				%_fcn%(_args)
				;if (regexmatch(_args,""""))
					;%_fcn%(_args)
				;else
					;%_fcn%(%_args%)
					;%_fcn%(_args)
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
	}
}

map(in, out, md)
{
	global
	asc_in := ""
	code = 0
	obj := {}

	; replace leader tags with the leader string
	in := regexreplace(in,"i)<leader>",leader)

	; replace prefix tags with the prefix string
	in := regexreplace(in,"i)<prefix>",prefix)

	; replace control tags with the anscii key
	while regexmatch(in, "i)<C-[a-z]>",str)
		in := regexreplace(in,str,ctrl(str))

	;in := regexreplace(in,"<([0-9]*)>",chr(32))

	; convert all input characters to ascii and append ";"
	loop, parse, in
	{
		transform, code, asc, %a_loopfield%
		code += 0
		;msgbox % "map -> in[" . a_loopfield . "]" . " asc[" . code . "]"
		asc_in .= code . ";"
	}

	; loop through all bits of the mode mask
	m_chk := 0x80 + 0
	while (m_chk > 0)
	{
		; check if the input characters are mapped during a particular mode
		if (m_chk & md)
		{
			;msgbox % "mode check:" . m_chk
			ndx := m_chk . ";" . asc_in

			errmsg := ""

			; look for keymap conflicts
			for wtype, key_map in maps[ndx]
			{
				if (wtype = win_type)
				{
					errmsg .= "`n   ascii keys:[" . in . "] mapped to:[" . key_map . "]" . " for win:" . win_type
				}
				;for a, b in key_map 
				{
					; go back to input to get next keystroke
					;if (regexmatch(index,"^" . ndx) || regexmatch(ndx,"^" . index))
						;errmsg .= "`n   ascii keys:[" . index . "] mapped to:[" . key_map.out . "]"
				}
			}

			if (errmsg != "")
			{
				errmsg := "keymap ignored:`n`tmode:[" . m_chk . "]`n`tmap: [" . in . "] ascii:[" . ndx . "]`n`tto  :[" . out . "]`n`n" . errmsg
				msgbox % errmsg
			}
			else
			{
				maps[ndx,win_type] := out
				if (asc_in = "106;")
				{	
					;msgbox % "keymap:`n`tmode:[" . m_chk . "]`n`tmap: [" . in . "] ascii:[" . ndx . "]`n`tto  :[" . maps[ndx,win_type] . "]`n`twin :[" . win_type . "]"

				}
			}
		}
		transform, m_chk, bitshiftright, m_chk, 1
	}
}
ctrl(blk)
{
	ltr := regexreplace(blk,"i)<C-([a-z])>","$L1")
	transform, code, asc, %ltr%
	transform, ctrl_key, chr, (code-96)
	return ctrl_key
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

toggle_vi2()
{
	global
	if (last_mode = N)
		set_mode(P)
	else if (last_mode = P)
		set_mode(N)
	else
	{
		msgbox "bad last mode"
	}
}
toggle_vi_obs()
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
	;last_mode := mode

	set_mode(0)
	soundbeep ,40,20
	sleep 50
	tooltip "got here"
	set_mode(last_mode)
	;set_mode()
}

set_mode(md_lit:=0)
{
	global
	;msgbox % "md_lit:" . md_lit
	if md_lit is number
		md := md_lit
	else
		md := %md_lit%

	if (mode and md_lit and last_mode != mode)
	{
		;msgbox % "last mode reset from " . last_mode . " to " . mode
		last_mode := mode
	}

	mode := md
	;msgbox % "mode " . mode . " last_mode: " . last_mode
	if(md = N)
	{
		;msgbox "mode N"
		update_vi_status_bar("AEEE00")
		WinSet, Transparent, 230, vi_status
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
		WinSet, Transparent, 230, vi_status
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
		writable := true
	}
	else if(md = P)
	{
		;msgbox "mode P"
		writable := true
		update_vi_status_bar("F1E58C")
		WinSet, Transparent, 030, vi_status
	}
	else
	{
		;msgbox "mode 0"
		;mode := last_mode
		mode := 0
		;set_mode(last_mode)
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
