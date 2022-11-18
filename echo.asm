; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		echo.asm
;		Purpose :	Echo keyboard input/output
;		Date :		14th November 2022
;		Author : 	Paul Robson (paul@robsons.org.uk)
;
; *******************************************************************************************
; *******************************************************************************************

 	*= $8000

Loop1:
		jsr 	$FFCF
		pha
		jsr 	$FFD2
		lda 	#32
		jsr 	$FFD2
		pla
		jsr 	PrintHex
		lda 	#13
		jsr 	$FFD2
		bra 	Loop1

PrintHex:
		pha
		lsr 	a
		lsr 	a
		lsr 	a
		lsr 	a
		jsr 	PrintNibl
		pla				
PrintNibl:
		and 	#15
		cmp 	#10
		bcc 	_PN2
		adc 	#6
_PN2:	adc 	#48
		jmp 	$FFD2				
	.end 
