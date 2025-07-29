; =============== S U B R O U T I N E =======================================


TitleScreenLoop:
	lda	#0
	sta	flashTimer
	lda	#$30
	sta	ppuctrlCopy
	lda	#$70
	jsr	WriteMapper
	jsr	DisableBGAndSprites
	jsr	DisableNMI
	jsr	ClearNametable
	jsr	ResetScrollPos
	jsr	ClearOamBuffer
	jsr	InitSoundEngine
	lda	#MUS_TITLE
	jsr	PlaySound
	ldx	#$1F

loc_B736:
	lda	titlePalette,x
	sta	paletteBuffer,x
	dex
	bpl	loc_B736
	jsr	DrawTitleScreen
	jsr	EnableNMI

loc_B744:
	jsr	nullsub_1
	jsr	WaitVblank
	jsr	ReadControllers
	lda	joy1Edge
	and	#$10	; was start pressed?
	beq	loc_B744
	rts
; End of function TitleScreenLoop


; =============== S U B R O U T I N E =======================================


DrawTitleScreen:
	ldx	#0
	lda	$2002
	lda	#$20
	sta	$2006
	lda	#$C6
	sta	$2006

loc_B763:
	lda	theWingOfText,x
	beq	loc_B76E
	sta	$2007
	inx
	bne	loc_B763

loc_B76E:
	ldx	#0
	lda	$2002
	lda	#$22
	sta	$2006
	lda	#$66
	sta	$2006

loc_B77D:
	lda	copyrightText,x
	beq	loc_B788
	sta	$2007
	inx
	bne	loc_B77D

loc_B788:
	ldx	#0
	lda	$2002
	lda	#$22
	sta	$2006
	lda	#$A6
	sta	$2006

loc_B797:
	lda	companyText,x
	beq	loc_B7A2
	sta	$2007
	inx
	bne	loc_B797

loc_B7A2:
	ldx	#0
	lda	#6
	sta	$0
	lda	#$21
	sta	$1
	lda	#6
	sta	tmpCount

loc_B7B0:
	lda	$2002
	lda	$1
	sta	$2006
	lda	$0
	sta	$2006
	ldy	#$14

loc_B7BF:
	lda	madoolaTiles,x
	sta	$2007
	inx
	dey
	bne	loc_B7BF
	lda	$0
	clc
	adc	#$20
	sta	$0
	dec	tmpCount
	bne	loc_B7B0
	rts
; End of function DrawTitleScreen

; ---------------------------------------------------------------------------
madoolaTiles:
	db	$FC,$FC,$62,$63,$64,$65,$66,$FC,$62,$69,$6A,$6B,$FC,$6D,$6B,$6D,$6B,$60,$66,$FC
	db	$70,$66,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7D,$61,$67,$76,$77
	db	$80,$FC,$82,$83,$84,$85,$86,$87,$88,$FC,$8A,$8B,$8C,$8D,$8E,$8D,$68,$6C,$86,$6E
	db	$90,$91,$92,$93,$94,$95,$96,$97,$98,$FC,$9A,$9B,$9C,$9D,$9E,$9F,$6F,$95,$96,$71
	db	$FC,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF,$7F,$FC,$A9,$81
	db	$FC,$B1,$B2,$B3,$FC,$FC,$FC,$89,$8F,$99,$A0,$FC,$A0,$FC,$89,$B0,$B4,$B5,$B6,$7F
titlePalette:
	db	$0F,$36,$26,$16
	db	$0F,$11,$21,$31
	db	$0F,$12,$22,$32
	db	$0F,$13,$23,$33
	db	$0F,$10,$20,$30
	db	$0F,$11,$21,$31
	db	$0F,$12,$22,$32
	db	$0F,$13,$23,$33
theWingOfText:
	db	'THE WING OF',0
copyrightText:
	db	'@ 1986 SUNSOFT',0
companyText:
	db	'SUN ELECTRONICS CORP.',0
