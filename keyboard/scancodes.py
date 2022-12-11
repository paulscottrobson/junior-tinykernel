# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		scancodes.py
#		Purpose :	Generate PS/2 tables etc (II)
#		Date :		6th August 2022
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import re,os,sys



rawPS2data = open("ps2.data").read(-1).strip().split("\n")
rawPS2data = [x.strip() for x in rawPS2data if not x.startswith("/")]

asciiTable = [ 0 ] * 256
for l in rawPS2data:
	ascOver = None 
	m = re.match("^(.*)\\[(.*)]$",l)
	if m is not None:
		ascOver = int(m.group(2))
		l = m.group(1).strip()
	m = re.match("^(.*?)\\:\\:(.*?)\\:\\:",l)
	assert m is not None,"Bad line "+l
	keycode = int(m.group(1).replace(" ",""),16)
	if keycode > 0x7F:
		keycode = (keycode & 0x7F) | 0x80
	asc = ord(m.group(2)[0])
	assert asciiTable[keycode] == 0
	asciiTable[keycode] = asc if ascOver is None else ascOver

print(";\n;\t This file is automatically generated.\n;")
print("ASCIIFromScanCode:")
for i in range(0,256):
	a = asciiTable[i]
	k = "'"+chr(a)+"'" if a >= 32 and a <= 126 else "chr$({0})".format(a)
	if a == 0:
		k = ""
	print("\t.byte\t${0:02x} ; ${1:02x} {2}".format(a,i,k))
print("\t.byte\t$FF\n")	


print("ShiftFixTable:\n")
for l in rawPS2data:
	m = re.match("^(.*)\\:\\:(.*?)\\:\\:(.*)$",l)
	if len(m.group(2)) == 1 and m.group(3) != "" and m.group(3)[0] != ' ':
		a1 = ord(m.group(2)[0])
		a2 = ord(m.group(3)[0])
		if (a1 ^ a2) != 32:
			print("\t.byte\t${0:02x},${1:02x}\t\t; {2} => {3}".format(a1,a2,chr(a1),chr(a2)))

print("\t.byte\t$FF\n")	
