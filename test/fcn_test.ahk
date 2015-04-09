SetKeyDelay,0

;map("q", "send", "foobar")
map("q", "foobar")
map("b", "z")
;b::sendinput,g

send(msg) {
    sendinput % msg
}

;map(hk, fun, arg*) {
map(hk, arg*) {
    Static funs := {}, args := {}
    funs[hk] := Func("send"), args[hk] := arg
    Hotkey, %hk%, Hotkey_Handle
    Return
Hotkey_Handle:
    funs[A_ThisHotkey].(args[A_ThisHotkey]*)
    Return
}
