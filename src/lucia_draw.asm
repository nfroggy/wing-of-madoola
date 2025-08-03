; =============== S U B R O U T I N E =======================================

; Increases Lucia's hit points or magic points
; In:

; A: XXXXXCTT
;
; C: Point count.
; 0 = increase by 500
; 1 = increase by 100
;
; TT: Point type
; 0 = current HP
; 1 = max HP
; 2 = current MP
; 3 = max MP

AddLuciaHPMP:
	sta	$B
	and	#3
	asl	a
	clc
	adc	#healthLo
	sta	$8
	tax
	jsr	SplitOutWordDigits
	lda	$B
	and	#4
	bne	loc_D278
	lda	#0
	sta	$9
	lda	#5
	sta	$A
	jmp	loc_D280
; ---------------------------------------------------------------------------

loc_D278:
	lda	#0
	sta	$9
	lda	#1
	sta	$A

loc_D280:
	ldx	#9
	jsr	SplitOutWordDigits4
	jsr	BCDAdd
	ldx	$8
	jsr	CombineWordDigits
	jmp	LimitLuciaHPMP
; End of function AddLuciaHPMP


; =============== S U B R O U T I N E =======================================


DrawLuciaObj:
	sta	spriteTileNum
	lda	roomChangeTimer
	beq	loc_D29D
	lda	#0
	sta	attackTimer
	jmp	loc_D3C1
; ---------------------------------------------------------------------------

loc_D29D:
	jsr	GetObjMetatile
	sta	luciaMetatile
	ldx	bossActiveFlag
	bne	loc_D2AE
	cmp	#$9E	; less than 9E? normal tile
	bcc	loc_D2AE
	cmp	#$A4	; >= 9E and < A4? warp door or end of level door
	bcc	loc_D2E1

loc_D2AE:
	lda	healthLo
	ora	healthHi
	beq	luciaDead
	lda	#0
	sta	luciaDoorFlag	; lucia's not at a door
	beq	loc_D321

luciaDead:
	lda	objDirection	; clear stunned timer
	and	#$80
	sta	objDirection
	lda	mapperValue	; map in the sprite bank with lucia's death animation
	and	#$F0
	ora	#3
	jsr	WriteMapper
	lda	#150
	sta	roomChangeTimer
	lda	#OBJ_LUCIA_DYING	; set the object type to "lucia dead"
	sta	objType
	jsr	InitSoundEngine		; clear any playing sounds
	lda	#MUS_GAME_OVER		; "game over" sound
	jsr	PlaySound
	lda	#SFX_LUCIA_HIT		; "lucia hit" sound
	jsr	PlaySound
	jmp	loc_D311
; ---------------------------------------------------------------------------

loc_D2E1:
	lda	luciaDoorFlag
	bne	loc_D321
	dec	luciaDoorFlag	; lucia's at a door
	lda	luciaMetatile
	cmp	#$A0		; >= A0? warp door
	bcs	loc_D309
	lda	stageNum	; otherwise we're at the end of the level door.
	cmp	highestReachedStageNum	; if we've previously completed the level...
	bcc	loc_D2F7
	lda	orbCollectedFlag	; ...or we've collected the orb, set up the transition to the next level
	beq	loc_D321

loc_D2F7:
	jsr	InitSoundEngine
	lda	#MUS_CLEAR
	jsr	PlaySound	; play the level complete jingle
	lda	#210
	sta	roomChangeTimer
	lda	#OBJ_LUCIA_LVL_END_DOOR
	sta	objType	; set lucia's object type to "end of level door"
	bne	loc_D311

loc_D309:
	lda	#30
	sta	roomChangeTimer
	lda	#OBJ_LUCIA_DOORWAY
	sta	objType	; set lucia's object type to "doorway"

loc_D311:
	lda	#$80
	sta	objXPosLo
	sta	objYPosLo
	lda	#2
	sta	scrollMode	; lock the scroll
	jsr	DeleteAllObjectsButLucia
	jmp	loc_D3DF
; ---------------------------------------------------------------------------

loc_D321:
	lda	luciaHurtPoints
	bne	loc_D328
	jmp	loc_D3B5
; ---------------------------------------------------------------------------

loc_D328:
	cmp	#$FF	; check for yokko-chan's "display keyword" flag
	beq	loc_D34C
	cmp	#$A0	; branch if it's not a powerup item
	bcc	loc_D36A
	lda	#SFX_ITEM	; play "item pickup" sound effect
	jsr	PlaySound
	lda	luciaHurtPoints
	cmp	#$A8	; less than 8? power up the corresponding weapon
	bcs	loc_D354	; greater than 8? it's an hp/mp powerup or an orb
	and	#7
	tax
	inc	weaponLevels,x
	lda	weaponLevels,x
	cmp	#4
	bcc	loc_D3B5
	lda	#3
	sta	weaponLevels,x
	bne	loc_D3B5

loc_D34C:
	lda	keywordDisplayFlag	; display the keyword if we haven't already
	bmi	loc_D3B5
	inc	keywordDisplayFlag
	bne	loc_D3B5

loc_D354:
	lda	luciaHurtPoints
	cmp	#$B0
	beq	loc_D360	; branch if it's an orb
	jsr	AddLuciaHPMP	; if it's not, add to hp or mp
	jmp	loc_D3B5
; ---------------------------------------------------------------------------

loc_D360:
	dec	orbCollectedFlag
	lda	#0	; orb restores 500 HP
	jsr	AddLuciaHPMP
	jmp	loc_D3B5
; ---------------------------------------------------------------------------

loc_D36A:
	lda	objDirection
	asl	a
	bne	loc_D3B5	; if lucia's already stunned, don't hit her again
	ror	a
	clc
	adc	#60	; otherwise, stun her for 1 second
	sta	objDirection
	lda	objYSpeed
	beq	loc_D37D
	lda	#$40; if lucia's in the air, bump her down
	bne	loc_D37F

loc_D37D:
	lda	#$80	; if she isn't, bump her up

loc_D37F:
	sta	objYSpeed
	lda	objDirection	; ???
	lda	rngVal
	and	#$7F
	sec
	sbc	#$40
	sta	objXSpeed
	lda	#OBJ_LUCIA_AIR_LOCKED	; set lucia's object type to "jumping, locked x movement"
	sta	objType
	lda	#SFX_LUCIA_HIT	; play "lucia hit" sound
	jsr	PlaySound
	ldx	#luciaHurtPoints
	jsr	SplitOutWordDigits4
	lda	$5
	sta	$6
	lda	$4
	sta	$5
	lda	#0
	sta	$4
	sta	$7
	ldx	#healthLo
	jsr	SplitOutWordDigits
	jsr	BCDSubtract
	ldx	#healthLo
	jsr	CombineWordDigits

loc_D3B5:
	lda	#0
	sta	luciaHurtPoints
	lda	objDirection
	and	#$7F
	beq	loc_D3C1
	dec	objDirection

loc_D3C1:
	jsr	LuciaSetScroll
	lda	cameraXPixels
	sta	$0
	lda	cameraYPixels
	sta	$1
	jsr	SetCameraPixels
	lda	cameraXPixels
	sec
	sbc	$0
	jsr	ScrollXRelative
	lda	cameraYPixels
	sec
	sbc	$1
	jsr	ScrollYRelative

loc_D3DF:
	lda	objXPosLo
	sta	luciaXPosLo
	lda	objXPosHi
	sta	luciaXPosHi
	lda	objYPosLo
	sta	luciaYPosLo
	lda	objYPosHi
	sta	luciaYPosHi
	lda	attackTimer
	beq	loc_D3F5
	dec	attackTimer

loc_D3F5:
	lda	#0
	sta	dispOffsetX
	sta	dispOffsetY
	lda	spriteTileNum
	cmp	#6
	bne	loc_D405
	lda	#8
	sta	dispOffsetY

loc_D405:
	lda	#0
	sta	spriteAttrs
	lda	spriteTileNum
	asl	a
	sta	$6
	tax
	jsr	GetLuciaFrame
	lda	byte_D486,x
	sta	spriteTileNum
	lda	objDirection
	pha
	lda	objType
	cmp	#OBJ_LUCIA_CLIMB
	bne	loc_D427
	asl	objDirection
	lda	objYPosHi
	lsr	a
	ror	objDirection

loc_D427:
	jsr	DrawObj
	lda	spriteX
	sta	luciaDispX
	lda	spriteY
	sta	luciaDispY
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	lda	objType
	cmp	#OBJ_LUCIA_CLIMB
	bne	loc_D461
	lda	attackTimer
	beq	loc_D461
	pla
	pha
	sta	objDirection
	lda	attackTimer
	cmp	#6
	bcs	loc_D457
	lda	#$24
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAMWithDir
	jmp	loc_D46E
; ---------------------------------------------------------------------------

loc_D457:
	lda	#$20
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAMWithDir
	jmp	loc_D46E
; ---------------------------------------------------------------------------

loc_D461:
	ldx	$6
	jsr	GetLuciaFrame
	lda	byte_D486+1,x
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAM

loc_D46E:
	pla
	sta	objDirection
	rts
; End of function DrawLuciaObj


; =============== S U B R O U T I N E =======================================


GetLuciaFrame:
	lda	attackTimer	; if lucia's not attacking, exit
	beq	locret_D485
	cmp	#6
	bcs	loc_D480
	txa	; show second attack frame
	clc
	adc	#$10
	tax
	rts
; ---------------------------------------------------------------------------

loc_D480:
	txa	; show first attack frame
	clc
	adc	#8
	tax

locret_D485:
	rts
; End of function GetLuciaFrame

; ---------------------------------------------------------------------------
byte_D486:
	db	$06
	db	$04
	db	$0A
	db	$08
	db	$0E
	db	$0C
	db	$0A
	db	$08
	db	$02
	db	$00
	db	$06
	db	$04
	db	$2C
	db	$00
	db	$2A
	db	$28
	db	$22
	db	$20
	db	$22
	db	$20
	db	$2C
	db	$20
	db	$2A
	db	$20
	db	$26
	db	$24
	db	$26
	db	$24
	db	$2C
	db	$24
	db	$2A
	db	$24
