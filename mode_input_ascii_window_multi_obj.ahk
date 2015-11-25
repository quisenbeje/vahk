#NoEnv ;adding the line #NoEnv anywhere in the script improves DllCall's performance when unquoted parameter types are used (e.g. int vs. "int").
#SingleInstance Force ; only one instance of the script is allowed to run
#WinActivateForce     ; forcfully activates window
#UseHook Off          ; Hotkeys will be implemented by the default method
SetBatchLines -1      ; script never sleeps (affects cpu utilization)
SetTitleMatchMode, 2
;SetTitleMatchMode, Slow
setkeydelay, -1
ListLines Off         ; omits subsequently executed lines from history
SendMode Input        ; best setting for send command
SetFormat,integer,d

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ISSUES
; ISS_01: send_it function cannot parse functino with multiple arguments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;setwindelay, 0 

mode := {}
mode.show := Func("mode_show")
mode.set := Func("mode_set")
mode.key_on := Func("mode_activate_support_key")
mode.key_off := Func("mode_deactivate_support_key")
;mode.prt1 := Func("prt1"); ISS_01
mode_set(this) {
	global mode
	if (mode.current != this)
		mode.last := mode.current
		;msgbox % "last mode reset from `n`t" . mode.last.show()
								;. "`nto`n`t" . mode.current.show()

	mode.current := this
	if (GetKeyState("ScrollLock", "T") && (mode.last.keyOff != ""))
		mode.last.key_off()

	if ((mode.current.keyAuto) && (mode.current.keyOn != ""))
		mode.current.key_on()

	;msgbox % "current:   " mode.current.show(); ISS_01
	update_vi_status_bar()
	sendevent {RCtrl}
	return
}
mode_show(this) {
	return % this.name ":={writable:" this.writable 
			. ",rgb:" this.rgb ",alpha:" this.alpha "}"
}
mode_activate_support_key(this) {
	if (!GetKeyState("ScrollLock", "T")) ; this will be 'true' if ScrollLock is toggled 'on'
	{
		SetScrollLockState, AlwaysOn
		ky := this.keyOn
		send %ky%
	}
}
mode_deactivate_support_key(this) {
	if (GetKeyState("ScrollLock", "T")) ; this will be 'true' if ScrollLock is toggled 'on'
	{
		ky := this.keyOff
		send %ky%
		SetScrollLockState, off
	}
}
; ISS_01
prt1(this,num,num2) {
;prt1(num,num2) {
	msgbox % this.name ": prt:" num " and " num2
}
Z := {name:"Z",  writable:false,  rgb:"FFFFFF",  alpha:230}
N := {name:"N",  writable:false,  rgb:"AEEE00",  alpha:230}
I := {name:"I",  writable:true,   rgb:"005FFF",  alpha:230}
V := {name:"V",  writable:false,  rgb:"FFA724",  alpha:230}
R := {name:"R",  writable:true,   rgb:"FF9EB8",  alpha:230
		, keyAuto:true, keyOn:"{insert}", keyOff:"{insert}"}
C := {name:"C",  writable:false,  rgb:"242321",  alpha:230, keyOn:"{alt down}", keyOff:"{alt up}"}
L := {name:"L",  writable:false,  rgb:"cF1E58",  alpha:230, keyOn:"{alt down}", keyOff:"{alt up}"}
F := {name:"F",  writable:true,   rgb:"AE2222",  alpha:230}
;F := {name:"F",  writable:true,   rgb:"AEEE00",  alpha:230}
P := {name:"P",  writable:true,   rgb:"F1E58C",  alpha:030}
Z.base := mode
N.base := mode
I.base := mode
V.base := mode
R.base := mode
C.base := mode
L.base := mode
F.base := mode
P.base := mode


create_vi_status_bar()
N.set()
keystream := ""
maps := {}
X := 0
vi_on := true
vi_status := ""
dir_bottom := true

; this array contains window names that only respond to command mode
nomap_winlist := ["GVIM", "mintty"]

transform, etr, chr, 10 ; store ascii value for enter to variable
transform, ex, chr, 27 ; store ascii value for escape to variable
;transform, pre, chr, 29 ; store ascii value for ctrl+] to variable
transform, spc, chr, 0x20 ; store ascii value for space to variable
pre := ";"


leader := ","
prefix := pre

; default keymaps to apply to all windows
win_type := ""

; commands {
map("q",":close()",[C,N])             ; quit vahk
map("p",":P.set()",C)         ; change to Pause mode
map("n",":N.set()",C)         ; change to List mode

  ; window manipulation
map("r",":win_swap_mon()",C)      ; swap monitors for active window
map("o",":win_max()",C)           ; only window on the monitor
;map("r",":win_min()",C)           ; hide the window
map("R",":reload_script()",C)           ; reload this script
map("<leader>h",":win_move(""left"")",C)  ; move the window to the left half of the monitor
map("<leader>j",":win_move(""down"")",C)  ; move the window to the lower half of the monitor
map("<leader>k",":win_move(""up"")",C)    ; move the window to the upper half of the monitor
map("<leader>l",":win_move(""right"")",C)  ; move the window to the left half of the monitor
map("d","!{f4}",C)                ; delete window
map("h",":C.key_on();+{tab}",C)                ; move left on the list
map("l",":C.key_on();{tab}",C)                 ; move right on th elist
map(spc,"^!{space};:I.set()",C)   ; send launchy key compbo
map("z","^!z",C)   ; send ahk key compbo for foobar
map(etr,":right_click()",C)   ; send ahk key compbo for foobar
;map("h",":L.set{};+{tab 2}",C)                ; move left on the list
;map("l",":L.set();{tab}",C)                 ; move right on th elist
;map("l",":set_mode(L)",C)         ; change to List mode
; } commands

; { window list mode
map("h","+{tab}",L)                ; move left on the list
map("l","{tab}",L)                 ; move right on th elist
;map(etr,"{alt up};:N.set()",L) ; change to normal mode
;map(etr,":L.key_off();:N.set()",L) ; change to normal mode
map(etr,"{alt up};:N.set()",L) ; change to normal mode
;map(ex,":set_mode(last_mode)",L)   ; change to the previous mode
;map(ex,":mode.last.set()",L)   ; change to the previous mode
map(ex,":N.set()",L) ; change to normal mode
; } window list mode

; { general motion
map("<C-h>","^!{home}{enter};^{pgup 2}",[N,V])
map("<C-l>","^!{home}{enter}",[N,V])
map("<C-f>",":move(""PgDn"")",[N,V])
map("<C-b>",":move(""PgUp"")",[N,V])
map("gg",":move(""top"")",[N,V])
map("G",":move(""bottom"")",[N,V])
map("0",":move(""home"")",[N,V])
map("$",":move(""end"")",[N,V])
map("w",":move(""next"")",[N,V])
map("b",":move(""front"")",[N,V])
map("e",":move(""last"")",[N,V])
map("{",":move(""para_up"")",[N,V])
map("}",":move(""para_down"")",[N,V])
map("jj",":N.set();:move(""down"")",I)
map("kk",":N.set();:move(""up"")",I)
map("jk",":N.set()",I)
map("kj",":N.set()",I)
map("zt",":scroll(""down"")",N)
map("zb",":scroll(""up"")",N)
map("h",":move(""left"")",[N,V])
map("j",":move(""down"")",[N,V])
map("k",":move(""up"")",[N,V])
map("l",":move(""right"")",[N,V])
; } motion

; { normal mode
;map(":",":set_mode(C)",N)
map("x","{del}",[N,V])
map("X","{backspace}",N)
map("d","^x;:N.set()",V)
map(">>","{tab}",[N,V])
map("<<","+{tab}",[N,V])
map("u","^z",N)
map("<C-r>","^y",N)
map(ex,"{esc}",N)
map("<leader>bl",":L.set();{tab}",N)
; } normal

map("~",":swap_case()",N)

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
;map("<prefix>",":set_mode(C)",P)
;map("<prefix>",":set_mode(C)",N)
;map("<leader>w",":set_mode(C)",N)
;map("qq",":set_mode(P)",N)
map("a","{right};:I.set()",N)
map("A","{end};:I.set()",N)
map("r",":R.set();:get_chr();:N.set()",N)
map("R",":R.set()",N)
map("v",":V.set()",N)
map("V","{home}+{end};:V.set()",N)

;map("i",":I.prt1(5,2)",N) ; ISS_01
map("i",":I.set()",N)
map("I","{home};:I.set()",N)
map("cc","{home}+{end}^x;:I.set()",N)
map("ciw",":get_word();^x;:I.set()",N)
map("C","+{end}^x;:I.set()",[N,V])
map("o","{end}{enter};:I.set()",N)
map("O","{home}{enter}{up};:I.set()",N)

; find keys
map("/","^f;:F.set();:set_dir(""bottom"")",N)
map("?","^f;:F.set();:set_dir(""top"")",N)
map(ex,"{esc};:N.set()",F)
map(etr,"{enter};:N.set()",F)


; copy/paste/etc
map("p","{right}^v",N)
map("P","^v",N|V)
map("y","^c{left};:N.set()",V)
map("yw","+^{right}^c{left};:N.set()",N)
;map("yiw","^{left}+^{right}^c{left};:set_mode(N)",N)
map("yiw",":get_word();^c{left};:N.set()",N)
map("yy","{home}+{end}^c",N)
map("Y","{home}+{end}^c",N)
map("dd","{home}+{end}^x",N)
map("D","+{end}^x",N)
;map("iw","^{left}+^{right}",V)
map("iw",":get_word()",V)
map("<C-s>",":word_beg()",N)
map("<C-d>",":word_end()",N)


win_type := "Microsoft Word"
map("<C-o>","+{f5}",N)
map("<C-i>","+{f5 3}",N)
map(etr,"{enter};{esc};:N.set();^h!d!r{enter}{tab 3}{enter}",F)
map("<leader>" . spc,"^h!d!r{down}{enter};{tab 3}{enter}",N)

map("<C-h>",":page(""left"")",[N,V])
map("<C-l>",":page(""right"")",[N,V])
map("<C-j>",":page(""down"")",[N,V])
map("<C-k>",":page(""up"")",[N,V])
win_type := ""

win_type := "Microsoft Excel"
map("i","{f2};:I.set()",N)
map("n",":look(""forward"")",N)
map("N",":look(""backward"")",N)
map("f","^f;:get_chr();{enter}{esc}{left};:set_dir(""bottom"")",N)
map("F","^f;:get_chr();{enter}{esc};:set_dir(""top"");:look(""forward"");{left}",N)
map("t","^f;:get_chr();{enter}{esc}{left 2};:set_dir(""bottom"")",N)
map("T","^f;:get_chr();{enter}{esc};:set_dir(""top"");:look(""forward"");{right}",N)
map("*",":get_word();^f;{enter}{esc};:set_dir(""bottom"");:look(""forward"")",N)
map("#",":get_word();^f;{enter}{esc};:set_dir(""top"");:look(""forward"")",N)
win_type := ""

;win_type := "i).*Mozilla.*"
;win_type := "i)firefox"
win_type := "Firefox"
map("<C-h>","^+{tab}",N)
map("<C-l>","^{tab}",N)
map("<C-k>","^l",N)
map("<C-j>","{f6}",N)
map("<leader>te","^t;:I.set()",N)
map("<leader>td","^w",N)
map("dd","^w",N)
map("<leader>t0","^0",N)
map("<leader>t1","^1",N)
map("<leader>t2","^2",N)
map("<leader>t3","^3",N)
map("<leader>t$","^9",N)
map("<leader>tr","{f5}",N)
map("<leader>ta","{f6}",N)
map("<leader>tc","{f7}",N)
map(":","^l;:I.set()",N)
map("<C-o>","{backspace}",N)
map("<C-i>","+{backspace}",N)
map("J","{tab}",N)
map("K","+{tab}",N)
map("n","^g",N)
map("N","^+g",N)
;map(etr,"{enter};:N.set()",I)
map("<C-j>","{dn}",I)
map("<C-k>","{up}",I)
win_type := ""
; in work
map(ex,":normalize()",[I,R,V])
;map(etr,"{enter};{esc};:set_mode(N);^H;!d;!R;!H",F)
;map("<C-s>","^h;!d;!r;{enter};{tab 3};{enter}",N)
;map("<C-s>","^h!d!r!c;{tab 3}{enter}",N)
;map("<leader><32>","^h!d!r{down}{enter};{tab 3}{enter}",N)
map("<leader>" . etr,"{enter}",N)
map(etr,":move(""down"");:move(""home"")",N)

;map("N","^!{home}{enter};{up}{left 4};^{pgup 2}",N|V)
;map("n","^!{home}{enter};{up}{left 4}",N|V)

gosub, forever
return

forever:
loop
{
	;input,strk,L1 I,,{esc}{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}{BS}
	if (mode.current.writable)
		input,strk,L1 M V T2,{RCtrl},
		;input,strk,L1 I M V T2,{Capslock}^{}},
		;input,strk,L1 I M V T2,,
	else
		input,strk,L1 M,{RCtrl}
		;input,strk,L1 I M,{Capslock}{LAlt},{Capslock}{tab},{LAlt}{tab},{tab},{space}
	
	;msgbox % "keyhit " . asc(strk)
	;gosub forever
	If InStr(ErrorLevel, "EndKey:")
	{
		tooltip, You entered "%strk%" and terminated the input with %ErrorLevel%.
		send {ctrl up}
		goto forever
	}
	if (ErrorLevel = "NewInput")
	{
		tooltip, You entered "%strk%" and terminated the input with %ErrorLevel%.
		goto forever
	}


	; check to see if this window is on the no-map list
	for ii, ele in nomap_winlist
	{
		if (winactive(ele) && (mode.current != P && mode.current != C))
		{
			if (!mode.current.writable)
				send %strk%
			P.set()
			goto forever
		}
	}

	if (ErrorLevel = "Timeout")
	{
		if (strlen(keystream))
			status_bar_blink()
		keystream := ""
		;continue
		goto forever
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

	settimer, RemoveToolTip, 5000

	keystream .= s_code . ";"
	;ndx := (mode.current.val + 0) . ";" . keystream
	ndx := (mode.current.name) . ";" . keystream
	;tooltip % "ndx " . ndx
	;sleep 1000
	; look mappings of the keystream for all window types
	for wt, km in maps[ndx]
	{
		;if (ndx = "1;44;116;")
			;tooltip % "keymap:`n`tmode:[" . mode . "]`n`tmap: [" . keystream . "] ascii:[" . ndx . "]`n`tto  :[" . km . "]`n`twin :[" . wt . "]"

		; check if active window is one of the wintypes
		;IfWinActive, %wt%
		if (winactive(wt) && wt != "")
		{
			tooltip % "win: " . wt . " keymap found: " . ndx . " => " . km
			; if so then send, clear keystream, and call gosub forever
			if (km != "")
			{
				sendit(km)
				keystream := ""
				goto forever
			}
		}
	}
	; if here check for default wintype
	if (maps[ndx,""] != "")
	{
		tooltip % "default keymap found: " . ndx . " => " . maps[ndx,""]
		sendit(maps[ndx,""])
		keystream := ""
		goto forever
	}
	; no direct match. check for parial
	else
	{
		for index, ele in maps
		{
			for wt, km in ele
			{
				; go back to input to get next keystroke
				if ((wt = "" || winactive(wt)) && regexmatch(index,"^" . ndx))
				{
					tooltip % "win: " . wt . " XXXpartial keymap found: " . index
					goto forever
				}
			}
		}

		; no possible key map match
		if (!mode.current.writable)
		{
			tooltip % "no match found for " . ndx
			status_bar_blink()
		}
	}
	keystream := ""
	goto forever

	RemoveToolTip:
	settimer, RemoveToolTip, Off
	tooltip
	return
}

sendit(msg) {
	global mode, I
	obj := {}
	params := []
	stringsplit, cmd_array, msg, `;
	loop, %cmd_array0%
	{
		cmd := cmd_array%a_index%
		;if regexmatch(cmd,"^:(?P<fcn>.*)\((?P<args>.*)\)",_)
		;if regexmatch(cmd,"^:(?P<obj>.*)\.(?P<fcn>.*)\((?P<args>.*)\)",_)
		if regexmatch(cmd,"^:(?P<obj>.*)\.(?P<fcn>.*)\((?P<args>.*)\)",_)
		{
			; ISS_01
			;msgbox % "obj:" _obj "`nfcn:" _fcn "`nargs:" _args "`nparams:" IsFunc(%_obj%[_fcn])
			loop, parse, _args, csv
			{
				msgbox %A_Index% ":" %A_LoopField%
				params.insert(%A_LoopField%)
			}
				;msgbox  %_arg%%A_Index%
			;msgbox "running " %cmd%
			;#(cmd)
			;msgbox "did it work?"
			obj := %_obj%
			if (isobject(obj))
			{
				; ISS_01
				;msgbox % "i am an object:" obj.name
				objfcn := objbindmethod(obj, _fcn)
				if (objfcn)
				{
					;msgbox % "i am a function; need " IsFunc(objfcn) " params" ; ISS_01
					%objfcn%(_args) ; command works
					;%objfcn%.(params*) ; command doesn't work
					;msgbox % "obj:" _obj " fcn:" . _fcn . " args:" . _args ; ISS_01
					;exitapp ; ISS_01
				}
				else
				{
					msgbox error with mapped object function: `"%_obj%.%_fcn%`" is not a valid function name
					exitapp
				}
			}
		}


		else if regexmatch(cmd,"^:(?P<fcn>.*)\((?P<args>.*)\)",_)
		{
			if (IsFunc(_fcn))
			{
				;msgbox % "fcn:" . _fcn . " args:" . _args
				%_fcn%(_args)
				;if (regexmatch(_args,""""))
					;%_fcn%(_args)
				;else
					;%_fcn%(%_args%)
					;%_fcn%(_args)
			}
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

*Capslock::
if (mode.current != C)
{
	global tk_last
	;input,strk,L1 V,{Capslock},{Capslock}
	;sendevent {RAlt}
	tk := A_tickCount
	; check for double tap of capslock
	if (tk_last && ((tk - tk_last) < 250))
	{
		;tooltip % "double: delta=" . (tk - tk_last)
		if (mode.current.name == "P")
			N.set()
		else
			P.set()
	}
	else
	{
		toggle_cmd()
		settimer,capup, 0
	}
	tk_last := tk
}
return

capup:
if (!getkeystate("Capslock", "P"))
{
	if (mode.current = C)
		toggle_cmd()
	settimer,capup, off
}
return

reload_script()
{
	reload
}

normalize()
{
	global X, N, keystream
	N.set()
	X = 0
	keystream :=""
}
right_click()
{
	;send,{Click right,%A_CaretX%, %A_CaretY%}
	send,+{F10}
}
page(dir)
{
	WinGetTitle,Title,A
	If instr(Title,"Microsoft Word")<>0
	{
		x_o := A_CaretX
		y_o := A_CaretY
		mv := ""

		WinGetPos, X, Y, Width, Height, A

		if (dir = """left""")
		{
			send,{home}
			pctX := 100 * (A_CaretX - X) / Width

			tooltip % "X:" . X . "  CaretX:" . A_CaretX . "  PctX:" . pctX
				. "  | Y:" . Y . "  CaretY:" . A_CaretY

			if (pctX > 50)
			{
				x_o := X + Width/3
				y_o := A_CaretY
				mv := "{home}"
			}
		}
		else if (dir = """right""")
		{
			send,{end}
			pctX := 100 * (A_CaretX - X) / Width
			tooltip % "X:" . X . "  CaretX:" . A_CaretX . "  PctX:" . pctX
				. "  | Y:" . Y . "  CaretY:" . A_CaretY

			if (pctX < 50)
			{
				x_o := X + Width*2/3
				y_o := A_CaretY
				mv := "{home}"
			}
		}
		else if (dir = """up""")
		{
			send,^!{PgUp}
			sleep 80
			y_o := A_CaretY
			mv := "{home}"
			;mv := "{PgUp}"
		}
		else if (dir = """down""")
		{
			send,^!{PgDn}
			sleep 80
			y_o := A_CaretY
			mv := "{home}"
			;mv := "{PgDn}"
		}
		else
		{
			msgbox "wrong argument to move page"
			exitapp
		}

		send,{ctrl up}{Click %x_o%, %y_o%}%mv%

	}

}

multiple(num)
{
	global X
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
	global mode, V, X
	keys_beg := (mode.current = V ? "{shift down}" : "")
	keys_end := (mode.current = V ? "{shift up}" : "")

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
	global dir_bottom
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
	global dir_bottom
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
	N.set()
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


map(in, out, md)
{
	global leader, prefix, maps, win_type
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
		asc_in .= code . ";"
	}

	; if array
	if (md.MaxIndex())
	{
		for ii, arr in md
			gosub ProcessMapping
	}
	; if not an array
	else
	{
		arr := md
		goto ProcessMapping
	}


	return

	ProcessMapping:
	;msgbox % "show @@ " arr.show()

	;ndx := arr.val . ";" . asc_in
	ndx := arr.name . ";" . asc_in

	errmsg := ""

	; look for keymap conflicts
	for wtype, key_map in maps[ndx]
	{
		if (wtype = win_type)
		{
			errmsg .= "`n   ascii keys:[" . ndx . "] mapped to:[" . key_map . "]" . " for win:" . win_type
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
		errmsg := "keymap ignored:`n`tmode:[" . arr.name . "]`n`tmap: [" . in . "] ascii:[" . ndx . "]`n`tto  :[" . out . "]`n`n" . errmsg
		msgbox % errmsg
	}
	else
	{
		maps[ndx,win_type] := out
		;if (asc_in = "44;116;101;")
			;msgbox % "keymap:`n`tmode:[" . m_chk . "]`n`tmap: [" . in . "] ascii:[" . ndx . "]`n`tto  :[" . maps[ndx,win_type] . "]`n`twin :[" . win_type . "]"

	}
	return
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
	global vi_status
	ypos := (A_ScreenHeight) - 120
	Gui, +AlwaysOnTop +Disabled -SysMenu +Owner +Border
	Gui,Show,X0 Y%ypos% w100 h100 NoActivate,vi_status
 	Gui,Add,Picture,x5 y5 w90 h90, %A_ScriptDir%\vahk3.png
	Gui, Color, 141413
	WinSet, Transparent, 230, vi_status
	Gui -Caption
}

toggle_cmd()
{
	global mode, C
	if (mode.current = C)
	{
		;send {alt up}
		mode.last.set()
	}
	else
	{
		C.set()
		;send {alt down}
	}
}

update_vi_status_bar(mdd:=0)
{
	global mode, vi_status

	if (!mdd)
		mdd := mode.current
	Gui, Color, % mdd.rgb
	WinSet, Transparent, % mdd.alpha, vi_status
}

status_bar_blink()
{
	global mode, Z

	update_vi_status_bar(Z)
	;set_mode(Z)
	soundbeep ,40,20
	sleep 50
	;set_mode(mode.last)
	update_vi_status_bar()
}

set_mode(md_in)
{
	global mode, Z, N, I, V, R, C, L, F, P

	; if md_in is an object
	if (md_in.name)
		md := md_in
	; if md_in is a variable
	else
		md := %md_in%

	if (mode.current != Z && mode.last != mode.current)
		mode.last := mode.current
		;msgbox % "last mode reset from `n`t" . mode.last.show()
								;. "`nto`n`t" . mode.current.show()

	mode.current := md
	update_vi_status_bar()
	return


	if(mode != C)
		send {alt up}
	;msgbox % "mode " . mode . " last_mode: " . last_mode
	if(md = N)
	{
		if (last_mode = R)
			send {insert}
	}
	else if(md = V)
	{}
	else if(md = I)
	{}
	else if(md = R)
	{
		send {insert}
	}
	else if(md = C)
	{}
	else if(md = L)
	{
		sleep 20
		send {alt down}{tab}
		sleep 20
		send +{tab}
		sleep 20
	}
	else if(md = F)
	{}
	else if(md = P)
	{}
	else
	{}
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
	global g_xs, g_ys
	g_xs%gi% := x
	g_ys%gi% := y
}
