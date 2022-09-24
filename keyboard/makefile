ifeq ($(OS),Windows_NT)
include ..\documents\common.make
else
include ../documents/common.make
endif

all: 
	python scancodes.py >..$(S)ps2convert.inc
	