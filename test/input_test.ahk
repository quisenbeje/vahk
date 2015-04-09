SetKeyDelay,0


;can't have hot key
;v::msgbox hello

array01 := {"x":"abc", "iw":"iwxx", "ciw":"ciwyy", "yiw":"yiwzz"}
nmap ("q","hello")
array01["m"]:="v"


loop {
	found_partial:=false
	input, x, L1
	for key, value in array01
	{
		tmp:= p x
		;msgbox tmp=%tmp% key=%key%
		if (key = tmp)
		{
			;msgbox match %tmp%
			sendplay %value%
			break
		}
		else if (substr(key,1,strlen(tmp)) = tmp)
		{
			;msgbox partial match %tmp%
			p:=tmp
			found_partial:=true
			break
		}
		else
		{
			;msgbox no match %tmp%
		}
	}
	if (!found_partial)
		p:= ""
}

nmap(in,arg)
{
	global 
	array01%in% := arg
	return
}

