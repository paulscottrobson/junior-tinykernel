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

tools: emulator fnxmgr

emulator:
	make -B -C ..$(S)junior-emulator
	$(CCOPY) ..$(S)junior-emulator$(S)jr256* bin

fnxmgr:	
	$(CDEL) temp$(S)*.*
	$(CCOPY) ..$(S)FoenixMgr$(S)FoenixMgr$(S)*.* temp
	$(CCOPY) temp$(S)fnxmgr.py temp$(S)__main__.py 
	zip temp$(S)fnxmgr.zip -j temp$(S)__main__.py temp$(S)constants.py temp$(S)foenix_config.py temp$(S)intelhex.py \
			temp$(S)pgx.py temp$(S)srec.py temp$(S)foenix.py temp$(S)pgz.py temp$(S)wdc.py
	$(CCOPY) temp$(S)fnxmgr.zip bin

run: monitor
	bin$(S)jr256 monitor.rom@m 

ram:
	python bin$(S)fnxmgr.zip --port $(TTYPORT) --boot ram
	python bin$(S)fnxmgr.zip --port $(TTYPORT) --binary monitor.rom --address $(LMONITOR)

flash:
	python bin$(S)fnxmgr.zip --port $(TTYPORT) --boot flash
	python bin$(S)fnxmgr.zip --port $(TTYPORT) --flash-bulk bulk.csv
