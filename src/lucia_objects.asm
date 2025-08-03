; ---------------------------------------------------------------------------
luciaXSpeedTbl:
	db	$00,$00,$18,$18,$18,$00,$E8,$E8,$E8	; speeds are 4.4 fixed point
	db	$00,$00,$1C,$1C,$1C,$00,$E4,$E4,$E4
	db	$00,$00,$20,$20,$20,$00,$E0,$E0,$E0
	db	$00,$00,$28,$28,$28,$00,$D8,$D8,$D8
luciaYSpeedTbl:
	db	$00,$F0,$F0,$00,$10,$10,$10,$00,$F0
	db	$00,$E8,$E8,$00,$18,$18,$18,$00,$E8
	db	$00,$E0,$E0,$00,$20,$20,$20,$00,$E0
	db	$00,$D8,$D8,$00,$28,$28,$28,$00,$D8
luciaJumpSpeedTbl:
	db	$B4,$AE,$A0,$80

; =============== S U B R O U T I N E =======================================


GetLuciaSpeedTblOffset:
	lda	bootsLevel
	asl	a
	asl	a
	asl	a
	clc
	adc	bootsLevel
	clc
	adc	directionPressed
	tax
	rts
; End of function GetLuciaSpeedTblOffset


; =============== S U B R O U T I N E =======================================


LuciaNormalObj:
	jsr	GetLuciaSpeedTblOffset
	lda	luciaXSpeedTbl,x
	sta	objXSpeed
	lda	luciaYSpeedTbl,x
	sta	objYSpeed
	lda	attackTimer
	beq	loc_CBA6	; don't move if you're attacking
	lda	#0
	sta	objXSpeed

loc_CBA6:
	jsr	SetObjDirection
	jsr	UpdateObjXPos
	jsr	CheckSolidBelow	; check ground collision
	bne	loc_CBBE
	lda	#$20	; falling speed
	sta	objYSpeed
	lda	#OBJ_LUCIA_AIR	; change lucia's object to "in air"
	sta	objType
	lda	#5
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CBBE:
	bit	joy1Edge		; check for jump
	bpl	loc_CBF7
	lda	#SFX_JUMP		; play jumping sound
	jsr	PlaySound
	ldx	bootsLevel
	lda	luciaJumpSpeedTbl,x
	sta	objYSpeed
	lda	#OBJ_LUCIA_AIR
	cpx	#2			; if the boots level is at least 2, the player can control Lucia's
	bcs	loc_CBD6		; movement when she's jumping
	lda	#OBJ_LUCIA_AIR_LOCKED	; otherwise, set lucia's object to "in air, locked movement"

loc_CBD6:
	sta	objType
	lda	#0			; clear the "using the wing of madoola" flag
	sta	usingWingFlag
	lda	hasWingFlag		; if the player has the wing, and is pressing down and A, and has enough
	beq	loc_CBF2		; magic, set the "using the wing of madoola" flag
	lda	joy1
	and	#4
	beq	loc_CBF2
	lda	#7
	jsr	MagicSubtractA
	bcc	loc_CBF2
	jsr	CombineWordDigits
	dec	usingWingFlag

loc_CBF2:
	lda	#5
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CBF7:
	lda	objXSpeed
	bne	loc_CC2B
	lda	objMetatile
	ldx	objYSpeed
	beq	loc_CC2B
	bpl	loc_CC09	; if lucia's moving down, check the below metatile
	sec			; otherwise check the above metatile
	sbc	#$11
	jmp	loc_CC0C
; ---------------------------------------------------------------------------

loc_CC09:
	clc
	adc	#$11

loc_CC0C:
	tax
	lda	collisionBuff,x
	cmp	#$1F			; solid ground? set y speed to 0
	bcc	loc_CC27
	cmp	#$24			; scenery? also set y speed to 0
	bcs	loc_CC27
	jsr	MetatileAlignObjX	; otherwise, it's a ladder
	jsr	UpdateObjYPos
	lda	#OBJ_LUCIA_CLIMB	; set lucia's object type to "climbing"
	sta	objType
	lda	#7
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CC27:
	lda	#0
	sta	objYSpeed

loc_CC2B:
	lda	attackTimer		; set up lucia's animation frame
	bne	loc_CC33
	lda	objXSpeed
	bne	loc_CC3E

loc_CC33:
	lda	joy1
	and	#4
	bne	loc_CC48
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CC3E:
	lda	frameCounter
	lsr	a
	lsr	a
	lsr	a
	and	#3
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CC48:
	lda	#6
	jmp	DrawLuciaObj
; End of function LuciaNormalObj


; =============== S U B R O U T I N E =======================================


LuciaLvlEndDoorObj:
	lda	roomChangeTimer
	cmp	#35		; turn off lucia's sprite to simulate her
	bcc	locret_CC58	; going through the door
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

locret_CC58:
	rts
; End of function LuciaLvlEndDoorObj


; =============== S U B R O U T I N E =======================================


LuciaDoorwayObj:
	lda	roomChangeTimer
	and	#4	; flash sprite on and off every 4 frames
	beq	locret_CC64
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

locret_CC64:
	rts
; End of function LuciaDoorwayObj


; =============== S U B R O U T I N E =======================================


LuciaDyingObj:
	ldx	roomChangeTimer
	cpx	#$5A
	bcs	LuciaDoorwayObj
	cpx	#$54
	bcc	loc_CC74
	lda	#6
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CC74:
	lda	#0
	sta	spriteAttrs
	lda	#$E0
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	lda	spriteX
	clc
	adc	#$10
	ldx	objDirection
	bpl	loc_CC8B
	sec
	sbc	#$20

loc_CC8B:
	sta	spriteX
	lda	#$E2
	sta	spriteTileNum
	jmp	Write16x16SpriteToOAM
; End of function LuciaDyingObj


; =============== S U B R O U T I N E =======================================


LuciaClimbingObj:
	lda	joy1Edge
	bpl	loc_CC9B
	jmp	loc_CD0E
; ---------------------------------------------------------------------------

loc_CC9B:
	jsr	GetLuciaSpeedTblOffset
	lda	luciaXSpeedTbl,x
	sta	objXSpeed
	lda	luciaYSpeedTbl,x
	sta	objYSpeed
	jsr	SetObjDirection
	lda	objXSpeed
	beq	loc_CCBD
	lda	objYPosLo
	bmi	loc_CCBD
	jsr	GetObjMetatile
	cmp	#$24
	bcc	loc_CCBD
	jmp	loc_CD01
; ---------------------------------------------------------------------------

loc_CCBD:
	lda	objYSpeed
	bmi	loc_CCE1
	jsr	UpdateObjYPos
	bne	loc_CD01
	ldx	objMetatile
	lda	collisionBuff,x
	cmp	#$24
	bcc	loc_CD17
	txa
	clc
	adc	#$11
	tax
	lda	collisionBuff,x
	cmp	#$24
	bcc	loc_CD17
	lda	objYPosLo
	bpl	loc_CD17
	bmi	loc_CD0E

loc_CCE1:
	jsr	UpdateObjYPos
	lda	objYPosLo
	bmi	loc_CD17
	ldx	objMetatile
	lda	collisionBuff,x
	cmp	#$24
	bcc	loc_CD17
	txa
	sec
	sbc	#$11
	tax
	lda	collisionBuff,x
	cmp	#$1F
	bcc	loc_CD01
	cmp	#$24
	bcc	loc_CD17

loc_CD01:
	lda	#$80
	sta	objYPosLo
	lda	#OBJ_LUCIA_NORMAL
	sta	objType
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CD0E:
	lda	#OBJ_LUCIA_AIR
	sta	objType
	lda	#5
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CD17:
	lda	#7
	jsr	DrawLuciaObj
	rts
; End of function LuciaClimbingObj


; =============== S U B R O U T I N E =======================================


LuciaAirObj:
	jsr	GetLuciaSpeedTblOffset
	lda	luciaXSpeedTbl,x
	sta	objXSpeed
	lda	usingWingFlag
	beq	LuciaAirLockedObj
	lda	#$E0
	sta	objYSpeed
	bit	joy1
	bmi	LuciaAirLockedObj
	lda	#0
	sta	usingWingFlag

LuciaAirLockedObj:
	jsr	SetObjDirection
	jsr	UpdateObjXPos
	lda	objYSpeed
	bmi	loc_CD4A
	jsr	CheckSolidBelow
	beq	loc_CD4A
	jsr	MetatileAlignObjY
	jmp	loc_CD58
; ---------------------------------------------------------------------------

loc_CD4A:
	jsr	UpdateObjYPos
	beq	loc_CD65
	lda	#0
	sta	objYSpeed
	sta	usingWingFlag
	jmp	loc_CD65
; ---------------------------------------------------------------------------

loc_CD58:
	lda	#$A
	sta	objTimer
	lda	#OBJ_LUCIA_NORMAL	; normial lucia
	sta	objType
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CD65:
	lda	objYSpeed
	bit	joy1		; jump should be floatier when you're holding A
	bmi	loc_CD6E
	clc
	adc	#$C

loc_CD6E:
	clc	; gravity when A is pressed
	adc	#7
	bmi	loc_CD79
	cmp	#$40
	bcc	loc_CD79
	lda	#$40

loc_CD79:
	sta	objYSpeed
	lda	#5
	jmp	DrawLuciaObj
; End of function LuciaAirObj
