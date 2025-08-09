; =============== S U B R O U T I N E =======================================


DrawObjNoOffset:
	lda	#0
	sta	dispOffsetX
	sta	dispOffsetY
; End of function DrawObjNoOffset


; =============== S U B R O U T I N E =======================================


DrawObj:
	jsr	CalcObjDispPos
	bne	Write16x16SpriteToOAMWithDir
	rts
; End of function DrawObj


; =============== S U B R O U T I N E =======================================


Write16x16SpriteToOAMWithDir:
	jsr	SetSpriteHFlip

Write16x16SpriteToOAM:
	jsr	CheckForFlicker
	bit	oamWriteDirectionFlag
	bmi	loc_C545
	ldx	oamWriteCursor
	cpx	#$FC
	bne	loc_C553
	ldx	#0
	beq	loc_C553

loc_C545:
	lda	oamWriteCursor
	sec
	sbc	#8
	tax
	cpx	#$FC
	bne	loc_C551
	ldx	#$F8

loc_C551:
	stx	oamWriteCursor

loc_C553:
	lda	spriteY
	sta	oamBuffer,x
	sta	oamBuffer+4,x
	lda	spriteTileNum
	sta	oamBuffer+1,x
	clc
	adc	#$10
	sta	oamBuffer+5,x
	lda	spriteAttrs
	sta	oamBuffer+2,x
	sta	oamBuffer+6,x
	asl	a
	bmi	notMirroredSprite
	lda	spriteX
	sta	oamBuffer+7,x
	sec
	sbc	#8
	sta	oamBuffer+3,x
	jmp	loc_C58A
; ---------------------------------------------------------------------------

notMirroredSprite:
	lda	spriteX
	sta	oamBuffer+3,x
	sec
	sbc	#8
	sta	oamBuffer+7,x

loc_C58A:
	bit	oamWriteDirectionFlag
	bmi	loc_C594
	txa
	clc
	adc	#8
	sta	oamWriteCursor

loc_C594:
	lda	#$FF
	rts
; End of function Write16x16SpriteToOAMWithDir


; =============== S U B R O U T I N E =======================================


DrawObj8x16NoOffset:
	lda	#0
	sta	dispOffsetX
	sta	dispOffsetY

DrawObj8x16:
	jsr	CalcObjDispPos
	bne	WriteSpriteToOAMWithDir
	rts
; End of function DrawObj8x16NoOffset


; =============== S U B R O U T I N E =======================================


WriteSpriteToOAMWithDir:
	jsr	SetSpriteHFlip
; End of function WriteSpriteToOAMWithDir


; =============== S U B R O U T I N E =======================================

; Writes sprite data to the OAM mirror
; Parameters:

; spriteX, spriteY, spriteAttrs, spriteTileNum: OAM values to write

WriteSpriteToOAM:
	lda	oamWriteCursor
	bit	oamWriteDirectionFlag	; $00: Start writing at start of OAM
; $80: Start writing at end of OAM
; This gets alternated every frame to allow for flickering
; if there's too many sprites onscreen
	bpl	loc_C5B1
	sec
	sbc	#4
	sta	oamWriteCursor

loc_C5B1:
	tax
	lda	spriteX
	sec
	sbc	#4
	sta	oamBuffer+3,x
	lda	spriteY
	sta	oamBuffer,x
	lda	spriteAttrs
	sta	oamBuffer+2,x
	lda	spriteTileNum
	sta	oamBuffer+1,x
	txa
	bit	oamWriteDirectionFlag
	bmi	loc_C5D3
	clc
	adc	#4
	sta	oamWriteCursor

loc_C5D3:
	lda	#$FF
	rts
; End of function WriteSpriteToOAM


; =============== S U B R O U T I N E =======================================

; Calculates the position that the currently loaded object should be displayed onscreen.
;
; Out:

; spriteX/spriteY: Object display coordinates
; A gets set to $0 if the object is offscreen
;

CalcObjDispPos:
	lda	objXPosLo
	sec
	sbc	cameraXLo
	sta	spriteX
	lda	objXPosHi
	sbc	cameraXHi
	lsr	a
	ror	spriteX
	lsr	a
	ror	spriteX
	lsr	a
	ror	spriteX
	lsr	a
	bne	objDispOffscreen
	ror	spriteX
	lda	spriteX
	clc
	adc	dispOffsetX
	sta	spriteX
	sec
	sbc	#8
	cmp	#$F1
	bcs	objDispOffscreen
	lda	objYPosLo
	sec
	sbc	cameraYLo
	sta	spriteY
	lda	objYPosHi
	sbc	cameraYHi
	lsr	a
	ror	spriteY
	lsr	a
	ror	spriteY
	lsr	a
	ror	spriteY
	lsr	a
	bne	objDispOffscreen
	lda	spriteY
	ror	a
	clc
	adc	dispOffsetY
	sec
	sbc	#9
	sta	spriteY
	cmp	#$D0
	bcc	loc_C626

objDispOffscreen:
	lda	#0
	rts
; ---------------------------------------------------------------------------

loc_C626:
	lda	#$FF
	rts
; End of function CalcObjDispPos


; =============== S U B R O U T I N E =======================================


SetSpriteHFlip:
	lda	spriteAttrs
	and	#$BF	; clear the "horizontal flip" bit
	sta	spriteAttrs
	lda	objDirection	; MSB is set when facing left
	lsr	a	; move it over a bit
	and	#$40	; isolate the "facing" bit
	eor	#$40	; change it so it's set when facing right (all the sprites are stored facing left)
	ora	spriteAttrs	; apply the bit to the OAM attributes
	sta	spriteAttrs
	rts
; End of function SetSpriteHFlip


; =============== S U B R O U T I N E =======================================

; objDirection serves double duty as an object flicker timer.
; If the lower bits are set, this function will abort sprite
; drawing (on for 2 frames, off for 2 frames, etc) to make the
; object flicker.

CheckForFlicker:
	lda	objDirection
	asl	a
	beq	locret_C64A
	lda	frameCounter
	and	#2
	beq	locret_C64A
	pla	; pull the return address off the stack so we return from the parent function
	pla
	lda	#$FF

locret_C64A:
	rts
; End of function CheckForFlicker

; ---------------------------------------------------------------------------

ResetOamWritePos:
	lda	oamWriteDirectionFlag
	eor	#$80
	sta	oamWriteDirectionFlag
	lda	#0
	sta	oamWriteCursor
	rts
