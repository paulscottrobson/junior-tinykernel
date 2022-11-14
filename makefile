ifeq ($(OS),Windows_NT)
include documents\common.make
else
include documents/common.make
endif


all: monitor.rom

monitor.rom : newmonitor.asm 
	make -B -C keyboard
	64tass  -q -c -b -o monitor.rom -L newmonitor.lst newmonitor.asm
	64tass  -q -c -b -o lockout.rom -L lockout.lst lockout.asm

	


	

