; =============== S U B R O U T I N E =======================================


DispKeyword:
	jsr	InitPPU
	lda	#$F	; show "THE KEYWORD IS" and wait 150 frames
	sta	paletteBuffer
	lda	#$25
	sta	paletteBuffer+1
	lda	#$29
	sta	paletteBuffer+2
	lda	#$2C
	sta	paletteBuffer+3
	lda	keywordTextPtr
	sta	tmpPtrLo
	lda	keywordTextPtr+1
	sta	tmpPtrHi
	ldx	#$21
	ldy	#$C9
	jsr	PrintText
	jsr	EnableNMI
	lda	#150
	jsr	WaitNFrames
	jsr	InitPPU	; show the keyword (neko dayo~) for 1 second
	ldx	#$21
	ldy	#$4C
	jsr	PrintText
	ldx	#$21
	ldy	#$6B
	jsr	PrintText
	ldx	#$21
	ldy	#$8C
	jsr	PrintText
	ldx	#$21
	ldy	#$EE
	jsr	PrintText
	jsr	EnableNMI
	lda	#60
	jmp	WaitNFrames
; End of function DispKeyword

; ---------------------------------------------------------------------------
keywordText:
	db	'THE KEYWORD IS',0
	db	$29,$2A,$00
	db	$3A,$3B,$3C,$3D,$00
	db	$2B,$2C,$00
	db	$3E,$3F,$5C,$5D,$5E,$5F,$00
keywordTextPtr:
	dw	keywordText
