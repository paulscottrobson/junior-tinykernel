; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		newmonitor.asm
;		Purpose :	Replacement monitor for tweaked UK101 Hardware (64x32 display)
;		Date :		6th July 2022
;		Author : 	Paul Robson (paul@robsons.org.uk)
;
; *******************************************************************************************
; *******************************************************************************************

zTemp0 = $FC 								; 2 byte memory units.

ClockMhz = 6 								; clock speed in MHz (affects repeat timing)
KeyboardInvert = 1 							; 0 if keyboard active high, 1 if active low.

StartWorkSpace = $200
XPosition = $203 							; X Character position
YPosition = $204 							; Y Character position
TextColour = $205 							; Text colour
CurrentPage = $206 							; current I/O page
LastKey = $207 								; last key press
KeyStatus = $208 							; status bits for keys, 16 x 8 bits = 128 bits.

EndWorkSpace = $208+16

CWidth = 80 								; display size
CHeight = 60

IOPageRegister = 1 							; select I/O Page

	.include "vicky.inc"
	.include "interrupt.inc"

 	*= $F000

; ********************************************************************************
;                                        
;                                	Page Switch
;                                        
; ********************************************************************************

SelectPage0:
	pha
	lda 	IOPageRegister
	and 	#$FC
SelectPageWrite:
	sta 	IOPageRegister
	sta 	CurrentPage
	pla
	rts

SelectPage1:
	pha
	lda 	IOPageRegister
	and 	#$FC
	ora 	#1
	bra 	SelectPageWrite

SelectPage2:
	pha
	lda 	IOPageRegister
	and 	#$FC
	ora 	#2
	bra 	SelectPageWrite

SelectPage3:
	pha
	lda 	IOPageRegister
	ora 	#3
	bra 	SelectPageWrite

; ********************************************************************************
;                                        
;                                	Clear Screen
;                                        
; ********************************************************************************

ClearScreen:
	phx
	jsr 	SelectPage3
	lda 	TextColour
	jsr 	_ScreenFill
	jsr 	SelectPage2
	lda 	#$20
	jsr 	_ScreenFill
	plx
	rts

_ScreenFill:	
	pha
	lda 	#$C0 								; fill D000-D7FF with $60
	sta 	zTemp0+1
	lda 	#$00
	sta 	zTemp0
	ldy 	#0
	pla
_CLSLoop:
	sta 	(zTemp0),y
	iny
	bne 	_CLSLoop
	inc 	zTemp0+1
	ldx 	zTemp0+1
	cpx 	#$D3
	bne 	_CLSLoop
	jsr 	SelectPage0

; ********************************************************************************
;                                        
;                                	Home Cursor
;                                        
; ********************************************************************************

HomeCursor:
	lda 	#0
	sta 	xPosition
	sta 	yPosition
	jsr 	UpdateCursor
	rts

; ********************************************************************************
;
;                     	  Update Cursor position in Vicky
;
; ********************************************************************************

UpdateCursor:
	pha
	lda 	xPosition
	sta 	$D014
	lda 	yPosition
	sta 	$D016
	pla
	rts

; ********************************************************************************
;
;                     Point zTemp0 at current cursor position
;
; ********************************************************************************

SetZTemp0CharPos:
	pha
	txa
	pha
	lda 	yPosition 						; zTemp0 = yPos
	sta 	zTemp0
	lda 	#0
	sta 	zTemp0+1
	ldx 	#6 								; x 80
_SZ0Shift:
	asl 	zTemp0
	rol 	zTemp0+1
	cpx 	#5
	bne 	_SZ0NoAdd
	clc
	lda 	zTemp0
	adc 	yPosition
	sta 	zTemp0
	bcc 	_SZ0NoAdd
	inc 	zTemp0+1
_SZ0NoAdd:		
	dex
	bne 	_SZ0Shift
	clc
	lda 	zTemp0 							; add in xPos
	adc 	xPosition
	sta 	zTemp0
	lda 	zTemp0+1 						; point to page D
	adc 	#$C0
	sta 	zTemp0+1
	pla
	tax
	pla
	rts	

; ********************************************************************************
;                                        
;                                	Print A in Hex
;                                        
; ********************************************************************************

PrintHex:
	pha
	lda 	#32
	jsr 	PrintCharacter
	pla
	pha
	pha
	lsr 	a
	lsr 	a
	lsr 	a
	lsr 	a
	jsr 	PrintNibble
	pla
	jsr 	PrintNibble
	pla
	rts
PrintNibble:
	and 	#15
	cmp 	#10
	bcc 	_PN0
	adc 	#6
_PN0:	
	adc 	#48
	jmp 	PrintCharacter

; ********************************************************************************
;                                        
;                                	Print Character
;                                        
; ********************************************************************************

PrintCharacter:
	pha
	phx
	phy

	ldx 	1
	phx
	jsr 	SelectPage2

	pha
	cmp 	#8
	beq 	_PCBackspace
	cmp 	#9
	beq 	_PCTab
	cmp 	#13 						
	beq 	_PCCRLF
	jsr 	SetZTemp0CharPos 				; all other characters
	sta 	(zTemp0)
	jsr 	SelectPage3
	lda 	TextColour
	sta 	(zTemp0)
	jsr 	SelectPage2
	inc 	xPosition
	lda 	xPosition
	cmp  	#CWidth
	bne 	_PCNotRight
	stz 	xPosition
	inc 	yPosition
	lda 	yPosition
	cmp 	#CHeight
	bne 	_PCNotRight
	dec 	yPosition
	jsr 	ScrollScreenUp
_PCNotRight:
	jsr 	SelectPage0
	jsr 	UpdateCursor
	pla

	plx 
	stx 	1

	ply
	plx
	pla
	rts

_PCTab:
	lda 	#' '
	jsr 	PrintCharacter
	lda 	xPosition
	and 	#7
	bne 	_PCTab
	bra 	_PCNotRight
	
_PCBackspace:
	lda 	xPosition
	beq 	_PCNotRight
	dec 	xPosition
	jsr 	SetZTemp0CharPos
	lda 	#' '
	sta 	(zTemp0)
	bra 	_PCNotRight

_PCCRLF:									; CR/LF
	lda 	#$20 							; fill with EOL $20
	jsr 	PrintCharacter
	lda 	xPosition 						; until back at left
	bne 	_PCCRLF
	bra 	_PCNotRight

; ********************************************************************************
;                                        
;                                Ignore Interrupts
;                                        
; ********************************************************************************

NMIHandler:
		rti

; ********************************************************************************
;
;								  Scroll Screen Up
;
; ********************************************************************************

ScrollScreenUp:
	tya
	pha
	jsr 	SelectPage3
	jsr 	_ScrollBank
	lda 	TextColour
	jsr 	_WriteBottomLine
	jsr 	SelectPage2
	jsr 	_ScrollBank
	lda 	#32
	jsr 	_WriteBottomLine
	pla
	tay
	rts

_WriteBottomLine
	pha
	lda 	#$70
	sta 	zTemp0
	lda 	#$D2
	sta 	zTemp0+1
	ldy 	#CWidth-1
	pla
_ScrollBottomLine:
	sta 	(zTemp0),y
	dey
	bpl 	_ScrollBottomLine
	rts

_ScrollBank
	lda 	#$C0
	sta 	zTemp0+1
	lda 	#$00
	sta 	zTemp0
	ldy 	#CWidth
_ScrollLoop:	
	lda 	(zTemp0),y
	sta 	(zTemp0)
	inc 	zTemp0
	bne 	_ScrollLoop
	inc 	zTemp0+1
	lda 	zTemp0+1
	cmp 	#$D3
	bne 	_ScrollLoop
	rts

; ********************************************************************************
;                                        
;                    ctrl-c check, returns Z flag set on error
;                                        
; ********************************************************************************

ControlCCheck:
	lda 	KeyStatus+2 				; check LCtrl pressed
	and 	#$10
	beq 	Exit2
	lda 	KeyStatus+4 				; check C pressed
	and 	#$02 						; non-zero if so
	eor 	#$02 				 		; Z set if so.
	rts
Exit2:
	lda 	#$FF 						; NZ set
	rts

; ********************************************************************************
;
;					Handle streams of keyboard data from IRQ
;
; ********************************************************************************

HandleKeyboard:
		pha
		phx
		phy

;		pha
;		jsr 	PrintHex
;		lda 	#"."
;		jsr 	PrintCharacter
;		pla

		pha 									; save new code
		;
		;		Set/clear bit in the KeyStatus area
		;
		pha 									; 2nd save
		pha 									; 3rd save
		and 	#$7F
		lsr 	a 								; divide by 8 -> X, offset in table
		lsr 	a
		lsr 	a
		tax
		pla 									; restore 3rd save
		and 	#7 								; count in Y
		tay
		lda 	#0
		sec
_HKGetBits:		
		rol 	a
		dey
		bpl 	_HKGetBits
		ply 									; restore 2nd save
		bmi 	_HKRelease
		ora 	KeyStatus,x  					; set bit
		bra 	_HKWrite
_HKRelease:
		eor 	#$FF 							; clear bit
		and 	KeyStatus,x
_HKWrite:
		sta 	KeyStatus,x
		;
		;		Process key if appropriate
		;
		pla 									; restore new code
		bmi 	_HKExit
		jsr 	ConvertInsertKey
_HKExit:				
		ply
		plx
		pla
		rts

; ********************************************************************************
;                                        
;			Key code A has been pressed, convert to ASCII, put into buffer
;                                        
; ********************************************************************************

ConvertInsertKey:
		tax 								; scan code in X
		lda 	ASCIIFromScanCode,x 		; get ASCII unshifted 
		beq 	_CIKExit 					; key not known
		tay 								; save in Y
		bmi 	_CIKEndShiftCheck 			; if bit 7 was set shift doesn't affect this.
		lda 	KeyStatus+5 				; check left shift
		and 	#4
		bne 	_CIKShift
		lda 	KeyStatus+6 				; check right shift
		and 	#$40
		beq 	_CIKEndShiftCheck
_CIKShift:
		ldx 	#254 						; check shift table.
_CIKShiftNext:		
		inx
		inx
		bit  	ShiftFixTable,x 			; end of table ?
		bmi 	_CIDefaultShift
		tya 								; found a match ?
		cmp 	ShiftFixTable,x
		bne 	_CIKShiftNext
		ldy 	ShiftFixTable+1,x 			; get replacement
		bra 	_CIKEndShiftCheck

_CIDefaultShift:							; don't shift control
		cmp 	#32
		bcc 	_CIKEndShiftCheck
		tya 								; default shift.
		eor 	#32
		tay		
_CIKEndShiftCheck: 							
		lda 	KeyStatus+3 				; check LCtrl pressed
		and 	#$20
		beq 	_CIKNotControl
		tya 								; lower 5 bits only on control.
		and 	#31
		tay 								
_CIKNotControl:		
		tya 	
_CIKExit:		
		sta 	LastKey
		rts

; ********************************************************************************
;                                        
;							New Read Keyboard routine
;                                        
; ********************************************************************************

NewReadKeyboard:
		lda 	LastKey 					; wait for key press
		beq 	NewReadKeyboard
		stz 	LastKey 					; clear queue
		rts

; ********************************************************************************
;                                        
;							Fake Screen Editing
;                                        
; ********************************************************************************

FakeKeyboardRead:
		jsr 	NewReadKeyboard 			; echo everything except CR, makes 
		cmp 	#13 						; it behave like the C64 with it's
		beq 	_FKRExit 					; line editing
		jsr 	PrintCharacter
_FKRExit:
		rts		

; ********************************************************************************
;                                        
;								Get key if available
;                                        
; ********************************************************************************

GetKeyIfPressed:
		lda 	LastKey 					; key or zero in A
		stz 	LastKey 					; consume if pressed, no op if not.
		ora 	#0 							; set Z and return
		rts
		
; ********************************************************************************
;                                        
;									System startup
;                                        
; ********************************************************************************

SystemReset:
	ldx		#$FF
	txs
	ldx 	#EndWorkSpace-StartWorkSpace
_SRClear:
	stz 	StartWorkSpace-1,x
	dex
	cpx 	#$FF
	bne 	_SRClear	
	jsr 	SelectPage0

    LDA #$FF
    ; Setup the EDGE Trigger 
    STA INT_EDGE_REG0
    STA INT_EDGE_REG1
    ; Mask all Interrupt @ This Point
    STA INT_MASK_REG0
    STA INT_MASK_REG1
    ; Clear both pending interrupt
    lda INT_PENDING_REG0
    sta INT_PENDING_REG0
    lda INT_PENDING_REG1
    sta INT_PENDING_REG1     

	jsr 	TinyVickyInitialise
	jsr 	Init_Text_LUT
	jsr 	LoadGraphicsLUT
	jsr 	ClearScreen
	inc 	yPosition
	inc 	yPosition

    lda #200
    sta VKY_LINE_CMP_VALUE_LO
    lda #0
    sta VKY_LINE_CMP_VALUE_HI
    lda #$01 
    sta VKY_LINE_IRQ_CTRL_REG

    SEI
    lda INT_PENDING_REG0  ; Read the Pending Register &
    and #JR0_INT01_SOL
    sta INT_PENDING_REG0  ; Writing it back will clear the Active Bit
    lda INT_MASK_REG0
    and #~JR0_INT01_SOL
    sta INT_MASK_REG0

    lda INT_PENDING_REG0  ; Read the Pending Register &
    and #JR0_INT02_KBD
    sta INT_PENDING_REG0  ; Writing it back will clear the Active Bit
    ; remove the mask
    lda INT_MASK_REG0
    and #~JR0_INT02_KBD
    sta INT_MASK_REG0                

	;
	jsr 	SelectPage0
	lda 	#1
	sta 	$D100
	stz 	$D101
	stz 	$D102
	stz 	$D103
	;
	inc 	$700
	lda 	$700
	and 	#15
	ora 	#64
	jsr 	$FFD2
	;
	jsr 	INITKEYBOARD
	cli
	
NextChar:	
	jsr 	NewReadKeyboard
	jsr 	PrintHex
	jsr 	PrintCharacter
	jmp 	NextChar

	.include "hardware.asm"
	.include "ps2convert.inc"

; ********************************************************************************
;
;							 Commodore Compatible Vectors
;
; ********************************************************************************
	
	* = $FFCF 									; CHRIN
	jmp 	FakeKeyboardRead	
	* = $FFD2 									; CHROUT
	jmp 	PrintCharacter
	* = $FFE1
	jmp 	ControlCCheck
	* = $FFE4
	jmp 	GetKeyIfPressed

; ********************************************************************************
;
;									6502 Vectors
;
; ********************************************************************************

	* =	$FFFA

	.word 	NMIHandler                       	; nmi ($FFFA)
	.word 	SystemReset                         ; reset ($FFFC)
	.word 	IRQHandler                          ; irq ($FFFE)

	.end 
