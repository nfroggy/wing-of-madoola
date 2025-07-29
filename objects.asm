; =============== S U B R O U T I N E =======================================


ApplyGravity:
	lda	objYSpeed
	clc
	adc	#9
	bvc	loc_D806
	lda	#$7F

loc_D806:
	sta	objYSpeed
	rts
; End of function ApplyGravity


; =============== S U B R O U T I N E =======================================

; Sets the object's speed and direction to point towards Lucia's X pos

MoveObjTowardsLucia:

; FUNCTION CHUNK AT CD80 SIZE 00000007 BYTES

	jsr	CmpLuciaX
	bcs	loc_D815
	lda	objXSpeed
	bpl	locret_D81C
	jmp	NegateXSpeedAndDirection
; ---------------------------------------------------------------------------

loc_D815:
	lda	objXSpeed
	bmi	locret_D81C
	jmp	NegateXSpeedAndDirection
; ---------------------------------------------------------------------------

locret_D81C:
	rts
; End of function MoveObjTowardsLucia


; =============== S U B R O U T I N E =======================================


CmpLuciaX:
	lda	objXPosLo
	cmp	luciaXPosLo
	lda	objXPosHi
	sbc	luciaXPosHi
	rts
; End of function CmpLuciaX


; =============== S U B R O U T I N E =======================================

; Unused

CmpLuciaY:

	lda	objYPosLo
	cmp	luciaYPosLo
	lda	objYPosHi
	sbc	luciaYPosHi
	rts
; End of function CmpLuciaY


; =============== S U B R O U T I N E =======================================

; Make the object turn around if it hits a wall

CheckForHitWall:

; FUNCTION CHUNK AT CD80 SIZE 00000007 BYTES

	jsr	UpdateObjXPos
	beq	locret_D837
	jmp	NegateXSpeedAndDirection
; ---------------------------------------------------------------------------

locret_D837:
	rts
; End of function CheckForHitWall


; =============== S U B R O U T I N E =======================================

; If the metatile below the object is blank, make the object turn around

CheckForDrop:

; FUNCTION CHUNK AT CD80 SIZE 00000007 BYTES

	lda	objMetatile
	clc
	adc	#$11
	tax
	lda	collisionBuff,x
	cmp	#$24	; '$'
	bcc	locret_D848
	jmp	NegateXSpeedAndDirection
; ---------------------------------------------------------------------------

locret_D848:
	rts
; End of function CheckForDrop


; =============== S U B R O U T I N E =======================================


ExplosionObj:
	lda	objTimer
	ror	a
	ror	a
	ror	a
	ror	a
	and	#$C0
	sta	spriteAttrs
	lda	objTimer
	sec
	sbc	#1
	bmi	loc_D879
	sta	objTimer
	cmp	#$A
	bcc	loc_D872
	cmp	#$14
	bcc	loc_D86B
	lda	#$4A
	sta	spriteTileNum
	jmp	DrawObjNoOffset
; ---------------------------------------------------------------------------

loc_D86B:
	lda	#$46
	sta	spriteTileNum
	jmp	DrawObjNoOffset
; ---------------------------------------------------------------------------

loc_D872:
	lda	#$58
	sta	spriteTileNum
	jmp	DrawObj8x16NoOffset
; ---------------------------------------------------------------------------

loc_D879:
	lda	frameCounter
	and	#$F0
	bne	loc_D88C
	lda	frameCounter
	and	#3
	clc
	adc	#$C
	sta	objHP
	lda	#OBJ_ITEM_PICKUP
	bne	loc_D88E

loc_D88C:
	lda	#OBJ_NONE

loc_D88E:
	sta	objType
	rts
; End of function ExplosionObj


; =============== S U B R O U T I N E =======================================


NomajiInitObj:
	jsr	PutObjOnFloor
	lda	#20
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	rts
; End of function NomajiInitObj


; =============== S U B R O U T I N E =======================================


NomajiObj:
	lda	#3
	sta	objAttackPower
	lda	#$82
	sta	spriteTileNum
	lda	objDirection
	and	#$7F
	beq	loc_D8B1
	jmp	loc_D8F2
; ---------------------------------------------------------------------------

loc_D8B1:
	jsr	CheckSolidBelow
	beq	loc_D8DC
	lda	rngVal
	clc
	adc	frameCounter
	cmp	#$F0
	bcc	loc_D8F2
	lda	#SFX_NOMAJI
	jsr	PlaySound
	jsr	UpdateRNG
	and	#$3F
	sta	objXSpeed
	lda	luciaXPosHi
	cmp	objXPosHi
	bcs	loc_D8D8
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed

loc_D8D8:
	lda	#$80
	sta	objYSpeed

loc_D8DC:
	lda	#$A2
	sta	spriteTileNum
	jsr	CheckForHitWall
	jsr	SetObjDirection
	jsr	ApplyGravity
	jsr	UpdateObjYPos
	beq	loc_D8F2
	lda	#$40
	sta	objYSpeed

loc_D8F2:
	lda	#3
	sta	spriteAttrs
	jmp	loc_D8F9
; ---------------------------------------------------------------------------

loc_D8F9:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_D90F
	lda	objDirection
	asl	a
	beq	loc_D907
	dec	objDirection

loc_D907:
	jsr	DrawObjNoOffset
	beq	loc_D90F
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------

loc_D90F:
	lda	#OBJ_NONE
	sta	objType
	rts
; End of function NomajiObj


; =============== S U B R O U T I N E =======================================


FireballObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	dec	objTimer
	beq	loc_D93C
	lda	objTimer
	cmp	#$73
	bcc	loc_D921
	jsr	MoveObjTowardsLucia

loc_D921:
	jsr	CalcObjXYPos
	jsr	ApplyGravity
	lda	#0
	sta	spriteAttrs
	lda	#$48
	sta	spriteTileNum
	jsr	DrawObj8x16NoOffset
	beq	locret_D93B
	lda	#$20
	sta	objAttackPower
	jmp	CheckObjLuciaCollision16x16
; ---------------------------------------------------------------------------

locret_D93B:
	rts
; ---------------------------------------------------------------------------

loc_D93C:
	jmp	EraseObj
; End of function FireballObj


; =============== S U B R O U T I N E =======================================


SpawnFireball:
	bit	rngVal
	bne	locret_D981
	jsr	UpdateRNG
	lda	#$FD
	sta	$0
	lda	#$63
	jsr	GetNextObjSlot
	bne	locret_D981
	lda	objXPosLo
	sta	objectTable+8,x	; xPosLo
	lda	objXPosHi
	sta	objectTable+7,x	; xPosHi
	lda	objYPosLo
	sta	objectTable+6,x	; yPosLo
	lda	objYPosHi
	sta	objectTable+5,x	; yPosHi
	lda	#120
	sta	objectTable+2,x	; timer
	lda	#$80
	sta	objectTable+3,x	; y speed
	jsr	UpdateRNG
	and	#$3F
	sta	objectTable+4,x	; x speed
	lda	#OBJ_FIREBALL
	sta	objectTable,x	; type
	lda	#SFX_FIREBALL
	jmp	PlaySound
; ---------------------------------------------------------------------------

locret_D981:
	rts
; End of function SpawnFireball


; =============== S U B R O U T I N E =======================================


ItemPickupObj:
	lda	#$80
	sta	objDirection
	lda	objHP	; used here to indicate the powerup type
	tax
	clc
	adc	#$A0	; flag that shows this is a powerup
	sta	objAttackPower
	lda	itemPickupTiles,x
	sta	spriteTileNum
	cpx	#$10
	bne	loc_D99F
	lda	frameCounter	; orb palette cycling
	and	#3
	clc
	adc	#$10
	tax

loc_D99F:
	lda	itemPickupPalettes,x
	sta	spriteAttrs
	lda	objHP
	cmp	#8
	bcs	loc_D9B2
	jsr	DrawObj8x16NoOffset
	beq	loc_D9D2
	jmp	loc_D9B7
; ---------------------------------------------------------------------------

loc_D9B2:
	jsr	DrawObjNoOffset
	beq	loc_D9D2

loc_D9B7:
	lda	objHP
	sec
	sbc	#$C
	cmp	#4
	bcs	loc_D9CB
	jsr	CheckSolidBelow
	bne	loc_D9CB
	jsr	ApplyGravity
	jsr	UpdateObjYPos

loc_D9CB:
	jsr	CheckObjLuciaCollision16x16
	cmp	#$FE
	bne	locret_D9DF

loc_D9D2:
	lda	roomNum
	cmp	#$F
	bne	loc_D9DB
	jsr	SetItemCollectedFlag

loc_D9DB:
	lda	#OBJ_NONE
	sta	objType

locret_D9DF:
	rts
; End of function ItemPickupObj

; ---------------------------------------------------------------------------
itemPickupTiles:
	db	$60	; regular sword
	db	$60	; flame sword
	db	$66	; magic bomb
	db	$62	; bound ball
	db	$64	; shield ball
	db	$68	; smasher
	db	$6A	; flash
	db	$BC	; boots
	db	$8B	; apple
	db	$89	; pot
	db	$AB	; scroll
	db	$A9	; spellbook
	db	$2E	; red potion (recovers hp)
	db	$2E	; purple potion (increases max hp)
	db	$2E	; blue potion (recovers mp)
	db	$2E	; yellow potion (increases max mp)
	db	$8D	; orb
itemPickupPalettes:
	db	$01
	db	$03
	db	$03
	db	$01
	db	$03
	db	$03
	db	$01
	db	$00
	db	$00
	db	$01
	db	$03
	db	$01
	db	$00
	db	$01
	db	$02
	db	$03
	db	$00
	db	$41
	db	$82
	db	$C3

; =============== S U B R O U T I N E =======================================


WingOfMadoolaObj:
	lda	#0
	sta	objDirection
	sta	dispOffsetY
	sta	dispOffsetX
	lda	#0
	sta	objXPosLo
	lda	#$38
	sta	objXPosHi
	lda	#$80
	sta	objYPosLo
	lda	#$3D
	sta	objYPosHi
	jsr	CalcObjDispPos
	beq	locret_DA8E
	lda	#$CF
	sta	spriteTileNum
	lda	#3
	sta	spriteAttrs
	lda	spriteX
	sec
	sbc	#8
	sta	spriteX
	lda	#2

loc_DA33:
	pha
	lda	#3

loc_DA36:
	pha
	jsr	WriteSpriteToOAM
	lda	spriteX
	clc
	adc	#8
	sta	spriteX
	lda	spriteTileNum
	clc
	adc	#$10
	sta	spriteTileNum
	pla
	sec
	sbc	#1
	bne	loc_DA36
	lda	spriteTileNum
	sec
	sbc	#$32
	sta	spriteTileNum
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	lda	spriteX
	sec
	sbc	#$18
	sta	spriteX
	pla
	sec
	sbc	#1
	bne	loc_DA33
	lda	spriteX
	clc
	adc	#8
	sta	spriteX
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	lda	#$AA
	sta	objAttackPower
	jsr	CheckObjLuciaCollision16x32
	cmp	#$FE
	bne	locret_DA8E
	dec	hasWingFlag
	lda	#OBJ_DARUTOS_INIT	; spawn darutos
	sta	objType
; clear object table (this doesn't delete this object because
; it still gets copied back into the table)
	jsr	DeleteAllObjectsButLucia
	jmp	PlayRoomSong
; ---------------------------------------------------------------------------

locret_DA8E:
	rts
; End of function WingOfMadoolaObj


; =============== S U B R O U T I N E =======================================


FountainObj:
	lda	#$80
	sta	objXPosLo
	sta	objYPosLo
	lda	frameCounter
	asl	a
	asl	a
	asl	a
	asl	a
	and	#$80
	sta	objDirection
	lda	#$9D
	sta	spriteTileNum
	lda	#2
	sta	spriteAttrs
	jsr	DrawObjNoOffset
	beq	locret_DAE6
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	lda	#$AF
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAM
	lda	spriteY
	sec
	sbc	#$20
	sta	spriteY
	lda	#2
	sta	spriteAttrs
	lda	#$41
	bit	objDirection
	bpl	loc_DACD
	lda	#$61

loc_DACD:
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAM
	lda	frameCounter
	and	#$F
	bne	locret_DAE6
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	lda	#$A8	; same as collecting a 500 hp powerup
	sta	objAttackPower
	jmp	CheckObjLuciaCollision16x32
; ---------------------------------------------------------------------------

locret_DAE6:
	rts
; End of function FountainObj
