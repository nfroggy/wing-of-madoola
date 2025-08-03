; =============== S U B R O U T I N E =======================================

; Unused

DebugSpriteViewer:

	jsr	DisableBGAndSprites
	jsr	DisableNMI
	jsr	ClearNametable
	lda	#$A0
	sta	$2000
	lda	#8
	sta	$0
	lda	#$21
	sta	$1
	lda	#0
	sta	$2
	ldy	#$10

loc_B58F:
	lda	$2002
	lda	$1
	sta	$2006
	lda	$0
	sta	$2006
	ldx	#$10
	lda	$2

loc_B5A0:
	sta	$2007
	clc
	adc	#$10
	dex
	bne	loc_B5A0
	clc
	adc	#1
	sta	$2
	lda	$0
	clc
	adc	#$20
	sta	$0
	bcc	loc_B5B9
	inc	$1

loc_B5B9:
	dey
	bne	loc_B58F
	lda	#$A0
	sta	ppuctrlCopy
	jsr	EnableBGAndSprites
	jsr	EnableNMI

loc_B5C6:
	jsr	WaitVblank
	jsr	ReadControllers
	jsr	nullsub_1
	lda	joy1Edge
	and	#$20	; pressing select advances to the next CHR bank
	beq	loc_B5DD
	lda	mapperValue
	clc
	adc	#1
	jsr	WriteMapper

loc_B5DD:
	lda	joy1
	and	#$10	; pressing start quits the viewer
	beq	loc_B5C6
	rts
; End of function DebugSpriteViewer
