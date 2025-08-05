; ---------------------------------------------------------------------------

ResetVector:
	sei
	cld
	ldx	#$FF	; init stack pointer
	txs
	inx
	stx	vramWriteCount
	stx	flashTimer
	stx	$2000
	stx	$4010	; disable DMC
	lda	#$40
	sta	$4017	; disable APU IRQ

.wait1:
	ldx	$2002
	bpl	.wait1

.wait2:
	ldx	$2002
	bpl	.wait2
	jsr	InitSoundEngine
	ldx	#$E0	; clear $E0 - $FF
	ldy	#0
	lda	#$20
	jsr	ClearMem
	lda	#$28
	sta	ppuctrlCopy
	sta	$2000
	lda	#$1E
	sta	ppumaskCopy
	sta	$2001
	jmp	StartGameCode

; =============== S U B R O U T I N E =======================================


SetPaletteBGColors:
	lda	paletteBuffer
	sta	paletteBuffer+4
	sta	paletteBuffer+8
	sta	paletteBuffer+$C
	sta	paletteBuffer+$10
	sta	paletteBuffer+$14
	sta	paletteBuffer+$18
	sta	paletteBuffer+$1C
	rts
; End of function SetPaletteBGColors


; =============== S U B R O U T I N E =======================================


NMIVector:
	php
	pha
	txa
	pha
	tya
	pha
	jsr	DisableBGAndSprites
	lda	doneFrame
	beq	.doNMI
	jmp	.exit
; ---------------------------------------------------------------------------

.doNMI:
	dec	doneFrame
	lda	mapperValue	; write to sunsoft-1 mapper
	sta	$6000
	lda	#0	; clear OAMADDR
	sta	$2003
	lda	#2	; DMA $200-$2FF to PPU OAM
	sta	$4014
	lda	vramWriteCount
	bne	.doVramWrite
	jsr	SetPaletteBGColors
	lda	$2002
	lda	#$3F	; write to palette
	sta	$2006
	lda	#0
	sta	$2006
	ldx	#0
	ldy	#$1F
	lda	flashTimer
	beq	.normalPalette
	dec	flashTimer

.flashPalette:
	lda	frameCounter
	asl	a	; mess with the palette to make the screen flash
	asl	a
	and	#$30
	clc
	adc	paletteBuffer,x
	sta	$2007
	inx
	dey
	bpl	.flashPalette
	bmi	.resetPPUAddr

.normalPalette:
	lda	paletteBuffer,x
	sta	$2007
	inx
	dey
	bpl	.normalPalette

.resetPPUAddr:
	lda	#$3F	; reset ppu address
	sta	$2006
	lda	#0
	sta	$2006
	sta	$2006
	sta	$2006
	beq	.writePPURegs

.doVramWrite:
	jsr	CopyToVRAM

.writePPURegs:
	lda	ppuctrlCopy
	sta	$2000
	lda	$2002
	lda	ppuXScrollCopy
	sta	$2005
	lda	ppuYScrollCopy
	sta	$2005

.exit:
	dec	frameTimer
	jsr	EnableBGAndSprites
	pla
	tay
	pla
	tax
	pla
	plp

IRQVector:
	rti
; End of function NMIVector
