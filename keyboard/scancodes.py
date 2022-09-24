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

import re 

# *******************************************************************************************
#
#		What we want is a table that maps PS/2 keycodes 00-7F onto SDL Key Codes (SDLK_)
#
#		The program then inverses this and uses it to generate a SDL Key code => PS/2 Keycode
#		table
#
# *******************************************************************************************

import os,re,sys

# *******************************************************************************************
#
#							This is scan code, unshifted, shifted data
#
# *******************************************************************************************

rawPS2data = """
02||1||!
03||2||@
04||3||#
05||4||$
06||5||%
07||6||^
08||7||&
09||8||*
0A||9||(
0B||0||)
0C||-||_
0D||=||+
0E||Backspace||
0F||Tab||
10||q||Q
11||w||W
12||e||E
13||r||R
14||t||T
15||y||Y
16||u||U
17||i||I
18||o||O
19||p||P
1A||[||{
1B||]||}
1E||a||A
1F||s||S
20||d||D
21||f||F
22||g||G
23||h||H
24||j||J
25||k||K
26||l||L
27||;||:
28||'||"
1C||Enter||
2A||Left Shift||
2C||z||Z
2D||x||X
2E||c||C
2F||v||V
30||b||B
31||n||N
32||m||M
33||,||<
34||.||>
35||/||?
36||Right Shift||
1D||Left Ctrl||
38||Left Alt||
39||Space||
01||Esc||
56||\\||
"""

fixupTable = []
highCode = 0 
codes = {}

for s in rawPS2data.strip().split("\n"):
	m = re.match("^([0-9A-F]+).*?\\|\\|(.*?)\\|\\|(.*?)$",s)
	assert m is not None,"Bad line "+s
	key = m.group(2)
	keyCode = ord(m.group(2)[0])
	shiftKey = ord(m.group(3)[0]) if m.group(3) != "" else 0
	scanCode = int(m.group(1),16)
	highCode = max(highCode,scanCode)
	if len(key) > 1:
		keyCode = 0
		shiftKey = 0
		if key == "Backspace":
			keyCode = 8
		if key == "Tab":
			keyCode = 9
		if key == "Enter":
			keyCode = 13
		if key == "Space":
			keyCode = 32
		if key == "Esc":
			keyCode = 76

	if shiftKey != 0:
		if (keyCode ^ shiftKey) != 32:
			fixupTable.append(keyCode)
			fixupTable.append(shiftKey)
	else:
		if keyCode != 0:
			keyCode |= 0x80

	codes[scanCode] = { "char":m.group(2),"code":m.group(3),"keycode":keyCode }

print(";\n;\t This file is automatically generated.\n;")
print("ASCIIFromScanCode:")
for i in range(0,144):
	print("\t.byte\t${0:02x} ; ${1:02x} {2}".format(codes[i]["keycode"] if i in codes else 0x00,i,codes[i]["char"] if i in codes else ""))
print("\t.byte\t$FF\n")	
print("ShiftFixTable:\n")
for c in fixupTable:
	print("\t.byte\t${1:02x} ; \"{0}\"".format(chr(c),c))
print("\t.byte\t$FF\n")	
