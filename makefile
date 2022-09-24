ifeq ($(OS),Windows_NT)
include documents\common.make
else
include documents/common.make
endif


all: monitor.rom

monitor.rom : newmonitor.asm vicky.inc hardware.asm
	make -C keyboard
	64tass -c -b -o monitor.rom -L newmonitor.lst newmonitor.asm
	python export.py

	


	

