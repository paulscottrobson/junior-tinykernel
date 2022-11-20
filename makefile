ifeq ($(OS),Windows_NT)
include documents\common.make
else
include documents/common.make
endif


all: monitor

monitor: 
	make -C keyboard
	64tass  $(AADDRESSES) -q -c -b -o monitor.rom -L output$(S)newmonitor.lst newmonitor.asm
	64tass  $(AADDRESSES) -q -c -b -o lockout.rom -L output$(S)lockout.lst lockout.asm
	64tass  $(AADDRESSES) -q -c -b -o echo.rom -L output$(S)echo.lst echo.asm

run: monitor
	$(CCOPY) ..$(S)junior-emulator$(S)jr256* .
	.$(S)jr256 monitor.rom@m echo.rom@b

	

