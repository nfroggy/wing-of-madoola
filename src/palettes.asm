; =============== S U B R O U T I N E =======================================


LoadRoomPalettes:
	lda	roomNum
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	#$F
	tay
	ldx	#$F

loc_B5F0:
	lda	roomBGPalettes,y
	sta	paletteBuffer,x
	lda	gameSpritePalettes,x
	sta	paletteBuffer+$10,x
	dey
	dex
	bpl	loc_B5F0
	rts
; End of function LoadRoomPalettes

; ---------------------------------------------------------------------------
roomBGPalettes:
	; room 0
	db	$26,$37,$16,$07
	db	$26,$17,$0A,$07
	db	$26,$39,$27,$07
	db	$26,$30,$31,$21
	; room 1
	db	$21,$37,$17,$07
	db	$21,$2A,$0A,$07
	db	$21,$3B,$30,$00
	db	$21,$30,$31,$21
	; room 2
	db	$21,$37,$17,$07
	db	$21,$2A,$0A,$07
	db	$21,$3B,$30,$00
	db	$21,$30,$31,$21
	; room 3
	db	$0F,$37,$17,$07
	db	$0F,$2A,$0A,$07
	db	$0F,$3B,$17,$0C
	db	$0F,$30,$13,$1C
	; room 4
	db	$0F,$10,$00,$0A
	db	$0F,$2A,$1A,$0A
	db	$0F,$3B,$30,$00
	db	$0F,$24,$13,$0C
	; room 5
	db	$0F,$07,$10,$0C
	db	$0F,$15,$26,$02
	db	$0F,$3C,$01,$11
	db	$0F,$25,$15,$04
	; room 6
	db	$0F,$26,$17,$08
	db	$0F,$09,$06,$2F
	db	$0F,$06,$08,$3F
	db	$0F,$02,$2A,$18
	; room 7
	db	$0F,$2B,$1C,$08
	db	$0F,$27,$16,$08
	db	$0F,$30,$10,$00
	db	$0F,$29,$1A,$09
	; room 8
	db	$0F,$3A,$27,$0C
	db	$0F,$1A,$0A,$07
	db	$0F,$3B,$30,$00
	db	$0F,$24,$13,$0C
	; room 9
	db	$0F,$23,$13,$08
	db	$0F,$17,$1B,$07
	db	$0F,$10,$00,$02
	db	$0F,$38,$16,$07
	; room 10
	db	$0F,$10,$00,$08
	db	$0F,$1A,$0C,$09
	db	$0F,$1B,$03,$07
	db	$0F,$15,$05,$3F
	; room 11
	db	$0F,$0A,$14,$07
	db	$0F,$2C,$1C,$0C
	db	$0F,$1C,$32,$21
	db	$0F,$3B,$21,$0C
	; room 12
	db	$00,$31,$22,$03
	db	$00,$0F,$0F,$0F
	db	$00,$16,$0F,$0F
	db	$00,$0F,$11,$2F
	; room 13
	db	$0F,$21,$11,$09
	db	$0F,$10,$00,$2F
	db	$0F,$10,$00,$01
	db	$0F,$24,$13,$0C
	; room 14
	db	$0F,$37,$00,$0F
	db	$0F,$13,$0B,$08
	db	$0F,$1B,$32,$00
	db	$0F,$20,$10,$00
	; room 15
	db	$0F,$05,$16,$08
	db	$0F,$2F,$2F,$18
	db	$0F,$3B,$00,$22
	db	$0F,$21,$1B,$17
gameSpritePalettes:
	db	$00,$12,$16,$36
	db	$00,$1A,$14,$30
	db	$00,$01,$11,$26
	db	$00,$00,$27,$37
	db	$FF
