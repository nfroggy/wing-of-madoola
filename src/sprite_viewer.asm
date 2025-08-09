; =============== S U B R O U T I N E =======================================

; Unused

DebugSpriteViewer:

	jsr	DisableBGAndSprites
	jsr	DisableNMI
	jsr	ClearNametable
	lda	#$A0
	sta	$2000
	lda	#$08	; vram write address low
	sta	$0
	lda	#$21	; vram write address high
	sta	$1
	lda	#0	; tile number
	sta	$2
	ldy	#$10	; number of rows to write
.drawLoop:
	lda	$2002	; clear write latch
	lda	$1	; write the address
	sta	$2006
	lda	$0
	sta	$2006
	ldx	#$10	; number of tiles per row
	lda	$2
.drawRow:
	sta	$2007
	clc
	adc	#$10	; this is for displaying sprite graphics, so tile numbers increment by 1 per row and 16 per column
	dex
	bne	.drawRow
	clc
	adc	#1
	sta	$2
	lda	$0
	clc
	adc	#$20
	sta	$0
	bcc	.noCarry
	inc	$1
.noCarry:
	dey
	bne	.drawLoop

	lda	#$A0
	sta	ppuctrlCopy
	jsr	EnableBGAndSprites
	jsr	EnableNMI

.displayLoop:
	jsr	WaitVblank
	jsr	ReadControllers
	jsr	nullsub_1
	lda	joy1Edge
	and	#JOY_SELECT	; pressing select advances to the next CHR bank
	beq	.noSelect
	lda	mapperValue
	clc
	adc	#1
	jsr	WriteMapper

.noSelect:
	lda	joy1
	and	#JOY_START	; pressing start quits the viewer
	beq	.displayLoop
	rts
; End of function DebugSpriteViewer
