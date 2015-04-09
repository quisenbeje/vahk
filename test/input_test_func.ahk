;SetKeyDelay,0
#NoEnv ;adding the line #NoEnv anywhere in the script improves DllCall's performance when unquoted parameter types are used (e.g. int vs. "int").
#SingleInstance Force ; only one instance of the script is allowed to run
#WinActivateForce     ; forcfully activates window
#UseHook Off          ; Hotkeys will be implemented by the default method
SetBatchLines -1      ; script never sleeps (affects cpu utilization)
ListLines Off         ; omits subsequently executed lines from history
SendMode Input        ; best setting for send command



array01 := {"x":"abc", "iw":"iwxx", "ciw":"ciwyy", "yiw":"yiwzz"}
;nmap ("q","hello")
nmap("q","h")
array01["m"]:="v"

sendit(msg) {
    sendinput % msg
}

nmap(in, arg*) {
	Static funs := {}, args := {}
	;funs[in] := Func("sendit"), args[in] := arg
	funs[in] := Func("softkey"), args[in] := arg
	;Stringleft, k1,in,1
	;msgbox %k1% %A_ThisHotKey%
	Hotkey, %in%, nmysend
	;Hotkey, %k1%, nmysend
	Return
nmysend:
	;funs[A_ThisHotKey].(args[A_ThisHotkey]*)
	funs[A_ThisHotKey].(args, A_ThisHotKey)
	Return
}
return

;can't have hot key
z::msgbox hello



softkey(ByRef hk,kp)
{
	found_partial:=false
	a1=hk[%kp%]
	msgbox % hk[kp]
	msgbox hk %hk% kp %kp% => hk[%kp%] a1
	input, x, L1
	for key, value in hk
	{
		tmp:= p x
		msgbox tmp=%tmp% key=%key%
		if (key = tmp)
		{
			msgbox match %tmp%
			sendplay %value%
			break
		}
		else if (substr(key,1,strlen(tmp)) = tmp)
		{
			msgbox partial match %tmp%
			p:=tmp
			found_partial:=true
			break
		}
		else
		{
			msgbox no match %tmp%
		}
	}
	if (!found_partial)
		p:= ""
}

