; =============== S U B R O U T I N E =======================================


ShowEndingAnimation:
	lda	#0
	sta	endingCursor
	sta	oamWriteDirectionFlag
	sta	objDirection
	lda	#$63
	jsr	WriteMapper
	jsr	EnableNMI
	jsr	WaitVblank
	ldx	#$F

.copyPalette:
	lda	endingSpritePalette,x
	sta	paletteBuffer+$10,x
	dex
	bpl	.copyPalette
	lda	#30	; show prince lying on ground
	jsr	EndingPrinceSprite
	lda	#0	; load lucia's sprite offscreen
	jsr	EndingLuciaSprite
	jsr	EndingLuciaRun	; show lucia running over to the prince
	lda	#10
	jsr	WaitNFrames
	lda	#30	; show lucia ducking down
	jsr	EndingLuciaSprite
	lda	#50	; show the prince getting up
	jsr	EndingPrinceSprite
	lda	#20	; show prince standing up
	jsr	EndingPrinceSprite
	lda	#40	; show lucia standing up
	jsr	EndingLuciaSprite
	lda	#40	; do a palette shift
	sta	flashTimer
	lda	#20
	jsr	WaitNFrames
	lda	#0	; lucia & prince transform into cool clothes
	jsr	EndingLuciaSprite
	lda	#80
	jsr	EndingPrinceSuitSprite
	lda	#$80
	sta	objDirection
	lda	#$70
	jsr	WriteMapper
	lda	#0	; lucia & prince face forwards
	jsr	EndingLuciaSprite
	lda	#120
	jmp	EndingPrinceSprite
; End of function ShowEndingAnimation

; ---------------------------------------------------------------------------
endingSpritePalette:
	db	$0F,$12,$16,$36
	db	$0F,$1A,$27,$36
	db	$0F,$25,$16,$36
	db	$0F,$2C,$27,$36

; =============== S U B R O U T I N E =======================================

; animates Lucia running to the prince

EndingLuciaRun:
	lda	#8
	sta	spriteX

.loop:
	jsr	WaitVblank
	lda	#$10
	sta	oamWriteCursor
	lda	spriteX
	lsr	a
	lsr	a
	lsr	a
	and	#3
	tax
	lda	luciaRunTiles,x
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAMWithDir
	lda	spriteTileNum
	clc
	adc	#2
	sta	spriteTileNum
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	jsr	Write16x16SpriteToOAMWithDir
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	lda	spriteX
	cmp	#120
	beq EndingSprite2.ret	
	clc
	adc	#1
	sta	spriteX
	jmp .loop	
; End of function EndingLuciaRun

; ---------------------------------------------------------------------------
luciaRunTiles:
	db	$04
	db	$08
	db	$0C
	db	$08

; =============== S U B R O U T I N E =======================================


EndingPrinceSprite:
	sta	endingTimer
	lda	#0
	beq EndingSpriteCommon
; End of function EndingPrinceSprite


; =============== S U B R O U T I N E =======================================


EndingLuciaSprite:
	sta	endingTimer
	lda	#$10

EndingSpriteCommon:
	sta	oamWriteCursor
	jsr	LoadEndingSprite
	jsr	Write16x16SpriteToOAMWithDir

EndingSprite2:
	jsr	LoadEndingSprite
	jsr	Write16x16SpriteToOAMWithDir
	lda endingTimer	
	beq .ret
	jmp	WaitNFrames
; ---------------------------------------------------------------------------

.ret:
	rts
; End of function EndingLuciaSprite


; =============== S U B R O U T I N E =======================================
; This subroutine is a workaround for the prince's head tiles for the "wearing
; suit and facing towards Lucia" frame being below each other in CHR ROM rather
; than being next to each other.

EndingPrinceSuitSprite:
	sta	endingTimer
	lda	#0
	sta	oamWriteCursor
	jsr	LoadEndingSprite
	jsr	WriteSpriteToOAMWithDir
	lda	spriteX
	sec
	sbc	#8
	sta	spriteX
	lda	spriteTileNum
	clc
	adc	#2
	sta	spriteTileNum
	jsr	WriteSpriteToOAMWithDir
	jmp EndingSprite2
; End of function EndingPrinceSuitSprite


; =============== S U B R O U T I N E =======================================


LoadEndingSprite:
	ldx	endingCursor
	lda	endingSpriteTbl,x
	sta	spriteY
	inx
	lda	endingSpriteTbl,x
	sta	spriteTileNum
	inx
	lda	endingSpriteTbl,x
	sta	spriteAttrs
	inx
	lda	endingSpriteTbl,x
	sta	spriteX
	inx
	stx	endingCursor
	rts
; End of function LoadEndingSprite

; ---------------------------------------------------------------------------
endingSpriteTbl:
	db	$A8,$CB,$01,$98
	db	$A8,$EB,$01,$88
	db	$A8,$00,$40,$08
	db	$98,$00,$40,$08
	db	$A0,$00,$40,$78
	db	$B0,$2C,$40,$78
	db	$A0,$AD,$01,$88
	db	$B0,$8F,$01,$88
	db	$98,$AD,$01,$88
	db	$A8,$AF,$01,$88
	db	$98,$E4,$40,$78
	db	$A8,$E6,$40,$78
	db	$98,$C4,$42,$78
	db	$A8,$E8,$42,$78
	db	$98,$8C,$43,$8C
	db	$A8,$EA,$43,$88
	db	$98,$09,$42,$78
	db	$A8,$0B,$42,$78
	db	$98,$0D,$03,$88
	db	$A8,$0F,$03,$88

; =============== S U B R O U T I N E =======================================


ShowEnding:
	jsr	InitSoundEngine
	jsr	InitPPU
	jsr	EnableNMI
	jsr	ShowEndingAnimation	; lucia runs over to the prince, helps him up, etc
	lda	#MUS_ENDING		; play ending music
	jsr	PlaySound
	lda	#$F			; init palette
	sta	paletteBuffer
	lda	#$39
	sta	paletteBuffer+1
	lda	#$29
	sta	paletteBuffer+2
	lda	#$19
	sta	paletteBuffer+3
	lda	#0
	sta	ppuYScrollCopy
	sta	nametablePosY
	sta	vramWriteCount
	lda	#MUS_ENDING
	jsr	PlaySound
	jsr	WaitVblank
	lda	endingTextPtr
	sta	tmpPtrLo
	lda	endingTextPtr+1
	sta	tmpPtrHi

.msgScrollLoop:
	jsr	EndingPrintMsgLine	; loop for scrolling up the ending message
	jsr	EndingScroll4Lines
	jsr	EndingPrintBlankLine
	jsr	EndingScroll4Lines
	lda	nametablePosY
	clc
	adc	#1
	jsr	HandleNametableWrapping
	sta	nametablePosY
	ldy	#0
	lda	(tmpPtrLo),y
	bne .msgScrollLoop  ; check for end of the message

	lda	#6			; wait 6 seconds on "the end" text
.dispTheEnd:
	pha
	lda	#60
	jsr	WaitNFrames
	pla
	sec
	sbc	#1
	bne .dispTheEnd
	rts
; End of function ShowEnding


; =============== S U B R O U T I N E =======================================


EndingScroll4Lines:
	lda	#4

.loop:
	pha
	lda	#1			; scroll down 1 px (moves text up)
	jsr	ScrollYRelative
	jsr	MoveEndingSpritesUp
	jsr	WaitVblank
	jsr	WaitVblank
	jsr	WaitVblank
	pla
	sec
	sbc	#1
	bne	.loop
	rts
; End of function EndingScroll4Lines

; ---------------------------------------------------------------------------
endingText:
	db	'   THE EVIL IS DEFEATED NOW.',0,1
	db	'    THE WING OF MADOOLA WILL',0,1
	db	'     BE BRIGHTING OVER THE',0,1
	db	'        WORLD FOR PEACE.',0,1
	db	$01
	db	$01
	db	'   YOU FINISHED THE ADVENTURE.',0,1
	db	'    THANK YOU FOR PLAYING AND',0,1
	db	'      HELPING LUCIA TO SAVE',0,1
	db	'           HER PRINCE.',0,1
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$20,$20,$20,$20,$20,$20,$20,$20,$20,$5B,$01,$02	; "The End" graphic
	db	$03,$04,$05,$20,$06,$07,$05,$21,$22,$23,$24,$00
	db	$20,$20,$20,$20,$20,$20,$20,$20,$15,$10,$11,$12
	db	$13,$14,$20,$20,$16,$14,$17,$25,$26,$27,$28,$00
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$00
endingTextPtr:
	dw	endingText

; =============== S U B R O U T I N E =======================================

; Moves the OAM slots used by the ending sprites up 1 pixel

MoveEndingSpritesUp:
	ldx	#$24

.loop:
	lda	oamBuffer,x
	cmp	#$F0    ; is the sprite's y pos offscreen?
	beq .nextSprite	
	sec     ; if not, move it up a pixel
	sbc	#1
	sta	oamBuffer,x

.nextSprite:
	txa
	sec
	sbc	#4
	tax
	bpl .loop	
	rts
; End of function MoveEndingSpritesUp


; =============== S U B R O U T I N E =======================================


EndingPrintMsgLine:
	ldy	#0
	lda	(tmpPtrLo),y
	iny
	cmp	#1
	beq .setupNextLine   ; 1 = blank line
	lda	#0
	sta	$0
	lda	nametablePosY
	sta	$1
	jsr	CalcVRAMWriteAddr
	jsr	VramWriteLinear
	ldy	#0

.copyMsg:
	lda	(tmpPtrLo),y
	beq .setupWrite	
	sta	vramWriteBuff,x
	iny
	inx
	bne	.copyMsg

.setupWrite:
	iny
	sty	nametableStartY
	stx	vramWriteCount
	jsr	VramSetWriteCount
	ldy	nametableStartY

.setupNextLine:
	tya	; add length of string to read cursor
	clc
	adc	tmpPtrLo
	sta	tmpPtrLo
	bcc .ret
	inc	tmpPtrHi

.ret:
	rts
; End of function EndingPrintMsgLine


; =============== S U B R O U T I N E =======================================


EndingPrintBlankLine:
	lda	#0
	sta	$0
	lda	nametablePosY
	clc
	adc	#1
	jsr	HandleNametableWrapping
	sta	$1
	jsr	CalcVRAMWriteAddr
	jsr	VramWriteLinear
	ldy	#$20
	lda	#' '

.loop:
	sta	vramWriteBuff,x
	inx
	dey
	bne .loop
	stx	vramWriteCount
	jmp	VramSetWriteCount
; End of function EndingPrintBlankLine
