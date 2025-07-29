; ---------------------------------------------------------------------------

NegateXSpeedAndDirection:
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed	; fall through...

; =============== S U B R O U T I N E =======================================


SetObjDirection:
	lda	objDirection
	ldx	objXSpeed
	beq	locret_CD98
	bmi	loc_CD94
	and	#$7F
	jmp	loc_CD96
; ---------------------------------------------------------------------------

loc_CD94:
	ora	#$80

loc_CD96:
	sta	objDirection

locret_CD98:
	rts
; End of function SetObjDirection


; =============== S U B R O U T I N E =======================================


CalcObjXYPos:
	jsr	CalcObjYPos

CalcObjXPos:
	lda	objXPosLo
	clc
	adc	objXSpeed
	sta	objXPosLo
	ror	a
	eor	objXSpeed
	bpl	locret_CDB0
	lda	objXSpeed
	bmi	loc_CDB1
	inc	objXPosHi
	inc	objMetatile

locret_CDB0:
	rts
; ---------------------------------------------------------------------------

loc_CDB1:
	dec	objXPosHi
	dec	objMetatile
	rts
; End of function CalcObjXYPos


; =============== S U B R O U T I N E =======================================


CalcObjYPos:
	lda	objYPosLo
	clc
	adc	objYSpeed
	sta	objYPosLo
	ror	a
	eor	objYSpeed
	bpl	locret_CDD9
	lda	objYSpeed
	bmi	loc_CDD0
	inc	objYPosHi
	lda	objMetatile
	clc
	adc	#$11
	sta	objMetatile
	rts
; ---------------------------------------------------------------------------

loc_CDD0:
	dec	objYPosHi
	lda	objMetatile
	sec
	sbc	#$11
	sta	objMetatile

locret_CDD9:
	rts
; End of function CalcObjYPos


; =============== S U B R O U T I N E =======================================


CheckIfEnemyHit16x16:
	ldx	#0
	beq	loc_CDE4
; End of function CheckIfEnemyHit16x16


; =============== S U B R O U T I N E =======================================


CheckIfEnemyHit16x32:
	ldx	#1
	bne	loc_CDE4
	ldx	#2

loc_CDE4:
	jsr	GetObjHitbox
	lda	flashTimer	; if flash is on, don't bother looking: every enemy onscreen is damaged every frame
	bne	enemyDamaged
	lda	objDirection
	and	#$7F		; check "stunned timer" portion
	cmp	#$A		; if it's less than 10, display the enemy normally
	bcc	loc_CE02
	lda	#$4A		; otherwise, overlay a "hit" graphic on top of the enemy
	sta	spriteTileNum
	lda	frameCounter	; use frameCounter to "randomly" set the mirroring
	asl	a		; this makes things more visually interesting
	asl	a
	and	#$C3
	sta	spriteAttrs
	jsr	Write16x16SpriteToOAM

loc_CE02:
	ldx	#$E

loc_CE04:
	lda	luciaProjectileCoords+1,x
	beq	loc_CE1A	; branch if there's no projectile in this slot
	lda	$1
	sec
	sbc	luciaProjectileCoords+1,x
	and	$3
	bne	loc_CE1A	; branch if the y values aren't in range
	lda	$0
	sec
	sbc	luciaProjectileCoords,x
	and	$2
	beq	enemyDamaged	; branch if there's a hit

loc_CE1A:
	dex	; check the next projectile
	dex
	bpl	loc_CE04
	jmp	CheckObjLuciaCollide	; if there's no hits, check if the enemy collided w/ lucia
; ---------------------------------------------------------------------------

enemyDamaged:
	lda	#1
	sta	luciaProjectileCoords+1,x
	lda	objHP
	sec
	sbc	weaponDamage
	sta	objHP
	bcc	enemyKilled
	lda	objDirection
	and	#$80	; clear stunned timer
	ora	#$10	; reset stunned timer
	sta	objDirection
	lda	#SFX_ENEMY_HIT	; play enemy hit sound
	jsr	PlaySound
	lda	#$FF
	rts
; ---------------------------------------------------------------------------

enemyKilled:
	lda	#30
	sta	objTimer
	lda	#OBJ_EXPLOSION	; change object type to "explosion"
	sta	objType
	lda	#SFX_ENEMY_KILL	; play enemy killed sound
	jsr	PlaySound
	lda	bossActiveFlag
	beq	loc_CE6B
	dec	numBossObjs
	bne	loc_CE6B	; did we just kill the last boss object?
	lda	#0
	sta	bossActiveFlag
	lda	#$63      ; delete all enemy objects
	jsr	DeleteAllObjectsAfterA
	jsr	PlayRoomSong	; change music to "boss defeated"
	lda	#SFX_BOSS_KILL	; play boss killed sound
	jsr	PlaySound
	ldx	stageNum
	lda	#$FF	; mark boss as defeated
	sta	bossDefeatedFlags,x

loc_CE6B:
	lda	#0
	rts
; End of function CheckIfEnemyHit16x32


; =============== S U B R O U T I N E =======================================

; In:

; X = 0: 16x16
; X = 1: 16x32
; X = 2: 32x32
;
; Out:

; $0, $1: Middle X/Y pixels of the sprites
; $2, $3: Bitmasks to apply to (the middle pixels - the target pixels) to get the hitbox areas

GetObjHitbox:
	lda	spriteX
	clc
	adc	xHitboxOffsets,x
	sta	$0
	lda	spriteY
	clc
	adc	yHitboxOffsets,x
	sta	$1
	lda	xHitboxBitmasks,x
	sta	$2
	lda	yHitboxBitmasks,x
	sta	$3
	rts
; End of function GetObjHitbox

; ---------------------------------------------------------------------------
xHitboxOffsets:
	db	$07,$07,$0F
yHitboxOffsets:
	db	$0F,$1F,$1F
xHitboxBitmasks:
	db	$F0,$F0,$E0
yHitboxBitmasks:
	db	$F0,$E0,$E0

; =============== S U B R O U T I N E =======================================


CheckObjLuciaCollision16x16:
	ldx	#0
	beq	loc_CE9F

CheckObjLuciaCollision16x32:
	ldx	#1
	bne	loc_CE9F
	ldx	#2

loc_CE9F:
	jsr	GetObjHitbox
; End of function CheckObjLuciaCollision16x16

; START OF FUNCTION CHUNK FOR CheckIfEnemyHit16x32

CheckObjLuciaCollide:
	lda	$0
	sec
	sbc	luciaDispX
	and	$2
	bne	loc_CEC7
	lda	$1
	sec
	sbc	luciaDispY
	sec
	sbc	#8	; check upper body collision
	tax
	and	$3
	beq	loc_CEC0
	txa
	clc
	adc	#16	; check lower body collision
	and	$3
	bne	loc_CEC7

loc_CEC0:
	lda	objAttackPower
	sta	luciaHurtPoints
	lda	#$FE
	rts
; ---------------------------------------------------------------------------

loc_CEC7:
	lda	#$FF
	rts
; END OF FUNCTION CHUNK FOR CheckIfEnemyHit16x32

; =============== S U B R O U T I N E =======================================

; Aligns the object's X position with the 16x16 metatile grid

MetatileAlignObjX:
	lda	#$80
	sta	objXPosLo
	rts
; End of function MetatileAlignObjX


; =============== S U B R O U T I N E =======================================

; Unused
; Assembler garbage? It's 8 bytes, just like the other garbage

AssemblerGarbage:

	lda	#$80
	sta	objYPosLo
	lda	#$80
	sta	objYPosLo
; End of function AssemblerGarbage


; =============== S U B R O U T I N E =======================================

; Aligns the object's Y position with the 16x16 metatile grid

MetatileAlignObjY:
	lda	#$80
	sta	objYPosLo
	rts
; End of function MetatileAlignObjY


; =============== S U B R O U T I N E =======================================


UpdateObjXPos:
	lda	objXPosLo
	clc
	adc	objXSpeed
	sta	objXPosLo
	ror	a
	eor	objXSpeed
	bmi	loc_CEEB
	jmp	CheckForSolidTileX	; run the check if we aren't moving to a new metatile
; ---------------------------------------------------------------------------

loc_CEEB:
	lda	objXSpeed
	bmi	loc_CEF7
	inc	objXPosHi
	jsr	IncObjMetatileX
	lda	#0
	rts
; ---------------------------------------------------------------------------

loc_CEF7:
	dec	objXPosHi
	jsr	DecObjMetatileX
	lda	#0
	rts
; End of function UpdateObjXPos


; =============== S U B R O U T I N E =======================================

; Unused

UpdateObjXYPos:

	jsr	UpdateObjXPos
; End of function UpdateObjXYPos


; =============== S U B R O U T I N E =======================================


UpdateObjYPos:
	lda	objYPosLo
	clc
	adc	objYSpeed
	sta	objYPosLo
	ror	a
	eor	objYSpeed
	bmi	loc_CF11
	jmp	CheckForSolidTileY
; ---------------------------------------------------------------------------

loc_CF11:
	lda	objYSpeed
	bmi	loc_CF1D
	inc	objYPosHi
	jsr	IncObjMetatileY
	lda	#0
	rts
; ---------------------------------------------------------------------------

loc_CF1D:
	dec	objYPosHi
	jsr	DecObjMetatileY
	lda	#0
	rts
; End of function UpdateObjYPos


; =============== S U B R O U T I N E =======================================

; inverts the object's x or y speed whenever it hits a wall or ceiling

MakeObjBounce:
	jsr	UpdateObjXPos
	beq	loc_CF31
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed

loc_CF31:
	jsr	UpdateObjYPos
	beq	locret_CF3D
	lda	#0
	sec
	sbc	objYSpeed
	sta	objYSpeed

locret_CF3D:
	rts
; End of function MakeObjBounce


; =============== S U B R O U T I N E =======================================

; Returns 0 if not touching a solid tile, $80 if object is

CheckForSolidTileX:
	lda	objXPosLo
	bpl	loc_CF52	; branch if less than halfway through a metatile
	lda	objXPosHi	; make sure x pos doesn't exceed the level
	cmp	#$7F
	beq	loc_CF7F
	lda	objXPosLo	; i'm pretty sure this branch will never be taken
	bpl	loc_CF84	; since it's a duplicate of the first one...
	ldx	objMetatile	; more than halfway through the metatile, so round up
	inx
	jmp	loc_CF5D
; ---------------------------------------------------------------------------

loc_CF52:
	lda	objXPosHi	; make sure x pos doesn't go off the level
	beq	loc_CF7F
	lda	objXPosLo
	bmi	loc_CF84	; branch if x more than halfway into tile
	ldx	objMetatile	; otherwise, round down
	dex

loc_CF5D:
	lda	collisionBuff,x
	cmp	#$1F
	bcc	loc_CF7F	; branch if solid tile
	lda	objYPosLo
	bpl	loc_CF73	; round down to a higher metatile
	cmp	#$A0
	bcc	loc_CF84	; 80-A0? exit
	txa	; >=A0? round up to the next metatile row
	clc
	adc	#$11
	jmp	loc_CF77
; ---------------------------------------------------------------------------

loc_CF73:
	txa
	sec
	sbc	#$11

loc_CF77:
	tax
	lda	collisionBuff,x
	cmp	#$1F
	bcs	loc_CF84	; branch if non-solid tile

loc_CF7F:
	lda	#$80
	sta	objXPosLo
	rts
; ---------------------------------------------------------------------------

loc_CF84:
	lda	#0
	rts
; End of function CheckForSolidTileX


; =============== S U B R O U T I N E =======================================

; Returns 0 if not touching a solid tile, $80 if object is

CheckForSolidTileY:
	lda	objYPosLo
	bmi	loc_CF97
	lda	objYPosHi
	beq	loc_CFC7
	lda	objMetatile
	sec
	sbc	#$11
	jmp	loc_CFA2
; ---------------------------------------------------------------------------

loc_CF97:
	lda	objYPosHi
	cmp	#$7F
	beq	loc_CFC7
	lda	objMetatile
	clc
	adc	#$11

loc_CFA2:
	tax
	lda	collisionBuff,x
	cmp	#$1F
	bcc	loc_CFC7
	lda	objXPosLo
	cmp	#$A8
	bcc	loc_CFB9
	inx
	lda	collisionBuff,x
	cmp	#$1F
	bcc	loc_CFC7
	dex

loc_CFB9:
	lda	objXPosLo
	cmp	#$58
	bcs	loc_CFCC
	dex
	lda	collisionBuff,x
	cmp	#$1F
	bcs	loc_CFCC

loc_CFC7:
	lda	#$80
	sta	objYPosLo
	rts
; ---------------------------------------------------------------------------

loc_CFCC:
	lda	#0
	rts
; End of function CheckForSolidTileY


; =============== S U B R O U T I N E =======================================

; Looks for solid metatiles below the object. Returns zero if
; there's none, or nonzero if there are any

CheckSolidBelow:
	lda	objYPosLo
	bpl	loc_CFE9
	ldx	objMetatile
	lda	objXPosLo
	cmp	#$58		; this is rounding code to determine which metatiles to check
	bcc	loc_CFE1	; if less than 5.5 pixels, look at previous and current metatiles
	cmp	#$A8
	bcc	loc_CFE6	; if between 5.5 & 10.5 pixels, look at current metatile
	bcs	loc_CFE2	; if more than 10.5 pixels, look at current and next metatiles

loc_CFE1:
	dex

loc_CFE2:
	jsr	FindSolidMetatileBelow
	inx

loc_CFE6:
	jsr	FindSolidMetatileBelow

loc_CFE9:
	lda	#0
	rts
; End of function CheckSolidBelow


; =============== S U B R O U T I N E =======================================


FindSolidMetatileBelow:
	lda	collisionBuff,x
	cmp	#$24
	bcc	loc_D001
	txa
	clc
	adc	#$11
	tax
	lda	collisionBuff,x
	cmp	#$24
	bcc	loc_D013	; branch if found solid block
	bcs	loc_D00D

loc_D001:
	txa
	clc
	adc	#$11
	tax
	lda	collisionBuff,x
	cmp	#$1F	; branch if the below block is not a ladder
	bcc	loc_D013

loc_D00D:
	txa
	sec
	sbc	#$11
	tax
	rts
; ---------------------------------------------------------------------------

loc_D013:
	pla	; return from parent function
	pla
	lda	#$80	; align y pos to metatiles
	sta	objYPosLo
	rts
; End of function FindSolidMetatileBelow


; =============== S U B R O U T I N E =======================================

; Unused

GetMetatileAbove:

	lda	objMetatile
	sec
	sbc	#$11
	tax
	lda	collisionBuff,x
	rts
; End of function GetMetatileAbove


; =============== S U B R O U T I N E =======================================


GetMetatileBelow:
	lda	objMetatile
	clc
	adc	#$11
	tax
	lda	collisionBuff,x
	rts
; End of function GetMetatileBelow


; =============== S U B R O U T I N E =======================================

; Returns the enemy spawn information for the screen the
; currently loaded object is located in.
; Information format:

; High nybble: Maximum number of onscreen enemies
; Low nybble: Enemy type offset

GetEnemySpawnInfo:
	lda	objXPosHi
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	and	#7
	sta	$0	; get 3 bits from x pos
	lda	objYPosHi
	lsr	a
	and	#$38
	ora	$0
	sta	$0	; next 3 bits are from y pos
	lda	roomNum
	and	#$F
	lsr	a	; high bits are from room number
	sta	$1
	bcc	loc_D050
	lda	$0
	ora	#$80
	sta	$0

loc_D050:
	lda	$0
	clc	; offset is 00000RRR R0YYYXXX
	adc	#low room0Enemies
	sta	$0
	lda	$1
	adc	#high room0Enemies
	sta	$1
	ldy	#0
	lda	(0),y
	rts
; End of function GetEnemySpawnInfo
