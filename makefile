ifeq ($(OS),Windows_NT)
include documents\common.make
else
include documents/common.make
endif


all: monitor

monitor: 
	make -C keyboard
	64tass  $(AADDRESSES) -q -c -b -o monitor.rom -L output$(S)newmonitor.lst newmonitor.asm
	64tass  $(AADDRESSES) -q -c -b -o lockout.rom -L output$(S)lockout.lst src$(S)lockout.asm

run: monitor
	$(CCOPY) ..$(S)junior-emulator$(S)jr256* bin
	bin$(S)jr256 monitor.rom@m 

	

