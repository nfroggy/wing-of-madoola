; =============== S U B R O U T I N E =======================================


SwordObj:
	lda	attackTimer
	beq	loc_D4EF
	lda	#1
	sta	spriteAttrs
	lda	attackTimer
	cmp	#6
	bcs	loc_D4B8
	lda	#1
	bne	loc_D4BA

loc_D4B8:
	lda	#0

loc_D4BA:
	ldx	objectTable+$A	; player direction
	bpl	loc_D4C2	; branch if facing right
	clc
	adc	#2

loc_D4C2:
	tax
	lda	spriteX
	clc
	adc	swordXOffsets,x
	sta	spriteX
	lda	spriteY
	clc
	adc	swordYOffsets,x
	sta	spriteY
	lda	swordAttrs,x
	ora	spriteAttrs
	sta	spriteAttrs
	and	#$80
	sta	objDirection
	lda	swordTiles,x
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAM
	jsr	WriteProjectileCoords
	beq	locret_D4F6
	lda	#0
	sta	attackTimer

loc_D4EF:
	lda	#OBJ_NONE
	sta	objType
	jmp	EraseProjectileCoords
; ---------------------------------------------------------------------------

locret_D4F6:
	rts
; End of function SwordObj

; ---------------------------------------------------------------------------
swordXOffsets:
	db	$FD,$10,$03,$F0
swordYOffsets:
	db	$F0,$06,$F0,$06
swordAttrs:
	db	$40,$40,$00,$00
swordTiles:
	db	$40,$42,$40,$42

; =============== S U B R O U T I N E =======================================


MagicBombFireObj:
	jsr	CalcObjXYPos

loc_D50A:
	lda	frameCounter
	asl	a
	asl	a
	asl	a
	asl	a
	asl	a
	and	#$80
	sta	spriteAttrs
	sta	dispOffsetY
	sta	dispOffsetX
	lda	#$44
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_D528
	jsr	WriteProjectileCoords
	bne	loc_D528
	rts
; ---------------------------------------------------------------------------

loc_D528:
	lda	#OBJ_NONE
	sta	objType
	jmp	EraseProjectileCoords
; End of function MagicBombFireObj


; =============== S U B R O U T I N E =======================================

; Spawned by the flame sword flame. These mostly serve the purpose
; of making sure that the flame sword creates a "wall of flame"

FlameSwordFireObj:
	dec	objTimer
	beq	loc_D536
	jmp	loc_D50A
; ---------------------------------------------------------------------------

loc_D536:
	lda	#OBJ_NONE
	sta	objType
	jmp	EraseProjectileCoords
; End of function FlameSwordFireObj


; =============== S U B R O U T I N E =======================================


MagicBombObj:
	lda	objTimer	; timer was initialized to 3
	beq	loc_D543
	dec	objTimer

loc_D543:
	lda	#$62
	sta	spriteTileNum
	lda	frameCounter
	asl	a
	and	#3
	sta	spriteAttrs	; palette shifting
	jsr	UpdateObjXPos
	bne	loc_D561
	jsr	DrawObj8x16NoOffset
	beq	loc_D5A4
	jsr	WriteProjectileCoords
	bne	loc_D561
	bit	joy1
	bvs	locret_D5AB	; don't split if player is still holding b

loc_D561:
	lda	objTimer
	bne	locret_D5AB
	lda	#SFX_BOMB_SPLIT	; play "magic bomb split" sound
	jsr	PlaySound
	ldx	#$16
	ldy	#6	; spawn 6 fireball objects

loc_D56E:
	lda	objectTable,x
	bne	loc_D59C
	lda	objXPosLo
	sta	objectTable+8,x	; x pos lo
	lda	objXPosHi
	sta	objectTable+7,x	; x pos hi
	lda	objYPosLo
	sta	objectTable+6,x	; y pos lo
	lda	objYPosHi
	sta	objectTable+5,x	; y pos hi
	lda	objMetatile
	sta	objectTable+1,x	; metatile
	lda	#OBJ_MAGIC_BOMB_FIRE
	sta	objectTable,x	; type
	lda	bombSpeedTbl,y
	sta	objectTable+3,x	; y speed
	lda	#0
	sta	objectTable+4,x	; x speed

loc_D59C:
	txa
	clc
	adc	#$B
	tax
	dey
	bpl	loc_D56E

loc_D5A4:
	jsr	EraseProjectileCoords
	lda	#OBJ_NONE
	sta	objType

locret_D5AB:
	rts
; End of function MagicBombObj

; ---------------------------------------------------------------------------
bombSpeedTbl:
	db	$90
	db	$B0
	db	$D0
	db	$F0
	db	$10
	db	$30
	db	$50

; =============== S U B R O U T I N E =======================================


BoundBallObj:
	dec	objTimer
	beq	loc_D5F5
	jsr	MakeObjBounce
	jsr	UpdateRNG
	and	#$1F
	sec
	sbc	#$10
	sta	dispOffsetX
	jsr	UpdateRNG
	and	#$1F
	sec
	sbc	#$10
	sta	dispOffsetY
	lda	frameCounter
	lsr	a
	and	#3
	sta	spriteAttrs
	lda	weaponLevels+3
	cmp	#3
	bcs	loc_D5E6
	lda	#$62
	sta	spriteTileNum
	jsr	DrawObj8x16
	beq	loc_D5F5
	bne	loc_D5EF

loc_D5E6:
	lda	#$4E
	sta	spriteTileNum
	jsr	DrawObj
	beq	loc_D5F5

loc_D5EF:
	jsr	WriteProjectileCoords
	bne	loc_D5F5
	rts
; ---------------------------------------------------------------------------

loc_D5F5:
	jsr	EraseProjectileCoords
	lda	#OBJ_NONE
	sta	objType
	rts
; End of function BoundBallObj


; =============== S U B R O U T I N E =======================================


ShieldBallObj:
	lda	frameCounter
	and	#3
	bne	loc_D607
	dec	objTimer
	beq	loc_D637

loc_D607:
	lda	currObjectIndex
	asl	a
	asl	a
	clc
	adc	frameCounter
	pha
	jsr	GetShieldBallX
	clc
	adc	luciaDispX
	sta	spriteX
	pla
	jsr	GetShieldBallY
	clc
	adc	luciaDispY
	sec
	sbc	#8
	sta	spriteY
	lda	#$62
	sta	spriteTileNum
	lda	frameCounter
	lsr	a
	clc
	adc	currObjectIndex
	and	#3
	sta	spriteAttrs
	jsr	WriteSpriteToOAM
	jmp	WriteProjectileCoords
; ---------------------------------------------------------------------------

loc_D637:
	jsr	EraseProjectileCoords
	lda	#OBJ_NONE
	sta	objType
	rts
; End of function ShieldBallObj

; ---------------------------------------------------------------------------
shieldBallPosTbl:
	db	$00
	db	$08
	db	$0F
	db	$16
	db	$1C
	db	$21
	db	$25
	db	$27
	db	$28
	db	$27
	db	$25
	db	$21
	db	$1C
	db	$16
	db	$0F
	db	$08
	db	$00
	db	$06
	db	$0C
	db	$12
	db	$17
	db	$1B
	db	$1E
	db	$1F
	db	$20
	db	$1F
	db	$1E
	db	$1B
	db	$17
	db	$12
	db	$0C
	db	$06
	db	$00
	db	$05
	db	$09
	db	$0D
	db	$11
	db	$14
	db	$16
	db	$18
	db	$18
	db	$18
	db	$16
	db	$14
	db	$11
	db	$0D
	db	$09
	db	$05

; =============== S U B R O U T I N E =======================================


GetShieldBallX:
	clc
	adc	#8
; End of function GetShieldBallX


; =============== S U B R O U T I N E =======================================


GetShieldBallY:
	and	#$1F
	cmp	#$F
	bcs	loc_D67F
	jsr	GetShieldBallOffset
	lda	shieldBallPosTbl,x
	rts
; ---------------------------------------------------------------------------

loc_D67F:
	and	#$F
	jsr	GetShieldBallOffset
	lda	#0
	sec
	sbc	shieldBallPosTbl,x
	rts
; End of function GetShieldBallY


; =============== S U B R O U T I N E =======================================

; Responsible for the "wavy" effect

GetShieldBallOffset:
	sta	$0
	lda	frameCounter
	lsr	a
	lsr	a
	and	#3
	tax
	lda	shieldBallOffsetTbl,x
	clc
	adc	$0
	tax
	rts
; End of function GetShieldBallOffset

; ---------------------------------------------------------------------------
shieldBallOffsetTbl:
	db	$00
	db	$10
	db	$20
	db	$10

; =============== S U B R O U T I N E =======================================


SmasherObj:
	lda	#SFX_ENEMY_HIT
	jsr	PlaySound
	bit	objHP	; this gets initialized to A by the weapon code
	bpl	loc_D6B2
	lda	#OBJ_SMASHER_DAMAGE	; once the "expand/contract" animation is done, have it home in on an enemy
	sta	objType
	lda	#1
	sta	objTimer
	rts
; ---------------------------------------------------------------------------

loc_D6B2:
	dec	objTimer
	bne	loc_D6C4
	lda	weaponLevels+5	; higher smasher level = shorter delay
	and	#3
	tax
	lda	smasherDelays,x
	sta	objTimer
	dec	objHP
	bmi	locret_D6D3

loc_D6C4:
	lda	objHP
	cmp	#6
	bcs	loc_D6D4
	jsr	CheckEnemies
	bne	loc_D6D6
	lda	#OBJ_NONE	; delete smasher object before the "shrink" part of the animation if there's no enemies onscreen
	sta	objType

locret_D6D3:
	rts
; ---------------------------------------------------------------------------

loc_D6D4:
	ldx	#0	; first part of animation: center around Lucia. Otherwise, X is
; initialized to the first enemy object in the objects list

loc_D6D6:
	lda	frameCounter
	asl	a
	asl	a
	asl	a
	asl	a
	and	#$C0
	sta	spriteAttrs
	lda	#$44
	sta	spriteTileNum
	lda	objectTable+8,x
	sta	objXPosLo
	lda	objectTable+7,x
	sta	objXPosHi
	lda	objectTable+6,x
	sta	objYPosLo
	lda	objectTable+5,x
	sta	objYPosHi
	lda	#0
	sta	dispOffsetX
	sta	dispOffsetY
	jsr	CalcObjDispPos
	lda	spriteX
	sta	$0
	lda	spriteY
	sta	$1
	ldx	objHP
	lda	smasherLimits,x
	sta	$2
	lda	smasherCenters,x
	sta	$3
	lda	#8	; there are 8 smasher fireball objects

loc_D717:
	pha
	jsr	UpdateRNG
	and	$2	; get a random value within the limit mask
	sec
	sbc	$3	; subtract to center it around the target object
	clc
	adc	$0
	sta	spriteX
	jsr	UpdateRNG
	and	$2
	sec
	sbc	$3
	clc
	adc	$1
	sta	spriteY
	jsr	Write16x16SpriteToOAM
	pla
	sec
	sbc	#1
	bne	loc_D717
	rts
; End of function SmasherObj

; ---------------------------------------------------------------------------
smasherLimits:
	db	$0F
	db	$1F
	db	$3F
	db	$7F
	db	$FF
	db	$FF
	db	$7F
	db	$3F
	db	$1F
	db	$0F
smasherCenters:
	db	$08
	db	$10
	db	$20
	db	$40
	db	$80
	db	$80
	db	$40
	db	$20
	db	$10
	db	$08
smasherDelays:
	db	$0A
	db	$06
	db	$03
	db	$01

; =============== S U B R O U T I N E =======================================

; Sets A to 0 if there are no enemies

CheckEnemies:
	ldx	#$63

loc_D756:
	lda	objectTable,x
	bne	locret_D766
	txa
	clc
	adc	#$B
	tax
	cmp	#$FD
	bcc	loc_D756
	lda	#0

locret_D766:
	rts
; End of function CheckEnemies


; =============== S U B R O U T I N E =======================================


SmasherDamageObj:
	lda	objTimer
	beq	loc_D77B
	dec	objTimer
	lda	#0
	sta	dispOffsetX
	lda	#0
	sta	dispOffsetY
	jsr	CalcObjDispPos
	jmp	WriteProjectileCoords
; ---------------------------------------------------------------------------

loc_D77B:
	jsr	EraseProjectileCoords
	lda	#OBJ_NONE
	sta	objType
	rts
; End of function SmasherDamageObj


; =============== S U B R O U T I N E =======================================


EraseProjectileCoords:
	lda	#$F8	; set sprite y pos offscreen
	sta	spriteY	; fall through to WriteProjectileCoords
; End of function EraseProjectileCoords


; =============== S U B R O U T I N E =======================================


WriteProjectileCoords:
	lda	currObjectIndex
	sec
	sbc	#1
	and	#7
	asl	a
	tax
	ldy	#0
	lda	luciaProjectileCoords+1,x
	cmp	#1
	bne	loc_D799
	dey

loc_D799:
	lda	spriteX
	sta	luciaProjectileCoords,x
	lda	spriteY
	clc
	adc	#8	; sprites are 8x16 so this gets the center
	cmp	#1
	bne	loc_D7A8
	lda	#2

loc_D7A8:
	sta	luciaProjectileCoords+1,x
	tya
	rts
; End of function WriteProjectileCoords


; =============== S U B R O U T I N E =======================================


FlameSwordFlameObj:
	jsr	CalcObjXYPos
	lda	frameCounter	; use the frame counter to flip the sprite vertically
	asl	a
	asl	a
	asl	a
	and	#$80
	sta	spriteAttrs
	lda	#$44	; 'D'
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	jsr	WriteProjectileCoords
	dec	objTimer
	beq	loc_D7F6
	lda	objTimer
	and	#1
	bne	locret_D7F5
	lda	#$63
	sta	$0
	lda	#$21
	jsr	GetNextObjSlot
	bne	locret_D7F5
	lda	objXPosLo
	sta	objectTable+8,x
	lda	objXPosHi
	sta	objectTable+7,x
	lda	objYPosLo
	sta	objectTable+6,x
	lda	objYPosHi
	sta	objectTable+5,x
	lda	#OBJ_FLAME_SWORD_FIRE
	sta	objectTable,x
	lda	objTimer
	sta	objectTable+2,x

locret_D7F5:
	rts
; ---------------------------------------------------------------------------

loc_D7F6:
	lda	#OBJ_NONE
	sta	objType
	jmp	EraseProjectileCoords
; End of function FlameSwordFlameObj
