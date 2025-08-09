; =============== S U B R O U T I N E =======================================

; IN: A - Number of frames to wait

WaitNFrames:
	inc	frameCounter
	pha
	jsr	WaitVblank
	pla
	sec
	sbc	#1
	bne	WaitNFrames
	rts
; End of function WaitNFrames


; =============== S U B R O U T I N E =======================================

; Converts a 16-bit word to an ASCII numeric string
; In: X- Address to low byte of the word
; Out: Writes the string to $04, writes $0004 to tmpPtr
; Clobbers $00-$08

WordToString:
	jsr	SplitOutWordDigits
	ldx	#3
	ldy	#0

.loop:
	lda	0,x
	clc
	adc	#'0'	; convert from digit to ascii
	sta	4,y
	iny
	dex
	bpl	.loop
	lda	#0
	sta	$8	; null-terminate the string
	lda	#4	; write the string pointer
	sta	tmpPtrLo
	lda	#0
	sta	tmpPtrHi
	rts
; End of function WordToString


; =============== S U B R O U T I N E =======================================


EnableBGAndSprites:
	lda	ppumaskCopy
	ora	#$18
	sta	ppumaskCopy
	sta	$2001
	rts
; End of function EnableBGAndSprites


; =============== S U B R O U T I N E =======================================


DisableBGAndSprites:
	lda	ppumaskCopy
	and	#$E7
	sta	ppumaskCopy
	sta	$2001
	rts
; End of function DisableBGAndSprites


; =============== S U B R O U T I N E =======================================


EnableNMI:
	lda	ppuctrlCopy
	ora	#$80
	sta	ppuctrlCopy
	sta	$2000
	rts
; End of function EnableNMI


; =============== S U B R O U T I N E =======================================


DisableNMI:
	lda	ppuctrlCopy
	and	#$7F
	sta	ppuctrlCopy
	sta	$2000
	rts
; End of function DisableNMI


; =============== S U B R O U T I N E =======================================

; In:

; X: PPU Address high
; Y: PPU Address low

SetPPUAddr:
	bit	$2002
	stx	$2006	; write high byte
	sty	$2006	; write low byte
	rts
; End of function SetPPUAddr


; =============== S U B R O U T I N E =======================================


ClearNametable:
	ldx	#$20
	bne	loc_B3ED
	ldx	#$24

loc_B3ED:
	ldy	#0
	jsr	SetPPUAddr
	lda	#$FC	; clear the nametable
	ldy	#$1E

loc_B3F6:
	ldx	#$20

loc_B3F8:
	sta	$2007
	dex
	bne	loc_B3F8
	dey
	bne	loc_B3F6
	ldx	#$40      ; clear the attribute table
	lda	#0

loc_B405:
	sta	$2007
	dex
	bne	loc_B405
	rts
; End of function ClearNametable


; =============== S U B R O U T I N E =======================================


ReadControllers:
	ldx	joyLatchVal	; this seems unnecessary...
	inx
	stx	$4016
	dex
	stx	$4016

	ldx	#8
.readLoop:
	lda	$4016	; read controller 1
	and	#3
	cmp	#1
	rol	joy1Edge	; carry -> bit 0
	lda	$4017	; read controller 2
	and	#3
	cmp	#1
	rol	joy2Edge
	dex
	bne	.readLoop

	ldx	#1
.calcEdge:
	ldy	joy1Edge,x	; joy values we just read into Y and A
	tya
	eor	joy1,x	; XOR last frame's joy vales
	and	joy1Edge,x	; pressed this frame AND not pressed last frame
	sta	joy1Edge,x
	sty	joy1,x
	dex
	bpl	.calcEdge
	rts
; End of function ReadControllers


; =============== S U B R O U T I N E =======================================

; X: Low byte of start addr
; Y: High byte of start addr
; A: Number of bytes to clear

ClearMem:
	stx	$E
	sty	$F
	tay
	dey
	lda	#0

.loop:
	sta	($E),y
	dey
	bpl	.loop
	rts
; End of function ClearMem


; =============== S U B R O U T I N E =======================================


ClearOamBuffer:

; FUNCTION CHUNK AT C64B SIZE 0000000B BYTES

	ldx	#0
	stx	!oamLen
	lda	#$F0

.loop:
	sta	oamBuffer,x	; put sprite y offscreen
	inx
	inx
	inx
	inx
	bne	.loop
	jmp	ResetOamWritePos
; End of function ClearOamBuffer


; =============== S U B R O U T I N E =======================================

; Unused

WaitVBlankEnd:
	lda	$2002
	bpl	WaitVBlankEnd
	rts
; End of function WaitVBlankEnd


; =============== S U B R O U T I N E =======================================


WaitVblank:

; FUNCTION CHUNK AT F3F8 SIZE 00000012 BYTES

	lda	#0
	sta	doneFrame

.loop:
	lda	doneFrame
	beq	.loop
	jmp	RunSoundEngine
; End of function WaitVblank


; =============== S U B R O U T I N E =======================================

; Unused

ReadMicrophone:

	lda	$4016
	eor	#$FF
	and	#4
	sta	micEdge
	tax
	eor	micData
	and	micEdge
	sta	micEdge
	stx	micData
	rts
; End of function ReadMicrophone


; =============== S U B R O U T I N E =======================================


WriteMapper:
	sta	mapperValue
	rts
; End of function WriteMapper


; =============== S U B R O U T I N E =======================================

; Unused

ResetScrollPosRight:

	lda	ppuctrlCopy
	ora	#1	; set rightmost nametable
	bne	ResetScrollPosCommon
; End of function ResetScrollPosRight


; =============== S U B R O U T I N E =======================================


ResetScrollPos:
	lda	ppuctrlCopy
	and	#$FE	; set leftmost nametable

ResetScrollPosCommon:
	sta	ppuctrlCopy
	lda	#0
	sta	ppuXScrollCopy
	sta	ppuYScrollCopy
	rts
; End of function ResetScrollPos
