; =============== S U B R O U T I N E =======================================


SwordObj:
	lda	attackTimer
	beq	.erase
	lda	#1
	sta	spriteAttrs
	lda	attackTimer
	cmp	#6
	bcs	.firstFrame
	lda	#1
	bne	.checkDir

.firstFrame:
	lda	#0

.checkDir:
	ldx	objectTable+$A	; player direction
	bpl	.facingRight ; branch if facing right
	clc
	adc	#2

.facingRight:
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
	beq	.return
	lda	#0
	sta	attackTimer

.erase:
	lda	#OBJ_NONE
	sta	objType
	jmp	EraseProjectileCoords
; ---------------------------------------------------------------------------

.return:
	rts
; End of function SwordObj

; ---------------------------------------------------------------------------
swordXOffsets:
	db	-3,16,3,-16
swordYOffsets:
	db	-16,6,-16,6
swordAttrs:
	db	$40,$40,$00,$00
swordTiles:
	db	$40,$42,$40,$42

; =============== S U B R O U T I N E =======================================


MagicBombFireObj:
	jsr	CalcObjXYPos

FlameObjCommon:
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
	beq	.erase
	jsr	WriteProjectileCoords
	bne	.erase
	rts
; ---------------------------------------------------------------------------

.erase:
	lda	#OBJ_NONE
	sta	objType
	jmp	EraseProjectileCoords
; End of function MagicBombFireObj


; =============== S U B R O U T I N E =======================================

; Spawned by the flame sword flame. These mostly serve the purpose
; of making sure that the flame sword creates a "wall of flame"

FlameSwordFireObj:
	dec	objTimer
	beq	.erase
	jmp	FlameObjCommon
; ---------------------------------------------------------------------------

.erase:
	lda	#OBJ_NONE
	sta	objType
	jmp	EraseProjectileCoords
; End of function FlameSwordFireObj


; =============== S U B R O U T I N E =======================================


MagicBombObj:
	lda	objTimer	; timer was initialized to 3
	beq	.doAnim
	dec	objTimer

.doAnim:
	lda	#$62
	sta	spriteTileNum
	lda	frameCounter
	asl	a
	and	#3
	sta	spriteAttrs	; palette shifting
	jsr	UpdateObjXPos
	bne	.split  ; hit wall? split
	jsr	DrawObj8x16NoOffset
	beq	.erase  ; offscreen? erase
	jsr	WriteProjectileCoords
	bne	.split  ; collided with an object? split
	bit	joy1
	bvs	.return    ; don't split if player is still holding b

.split:
	lda	objTimer
	bne	.return
	lda	#SFX_BOMB_SPLIT	; play "magic bomb split" sound
	jsr	PlaySound
	ldx	#$16
	ldy	#6	; spawn 6 fireball objects

.loop:
	lda	objectTable,x
	bne	.nextObj
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

.nextObj:
	txa
	clc
	adc	#$B
	tax
	dey
	bpl	.loop

.erase:
	jsr	EraseProjectileCoords
	lda	#OBJ_NONE
	sta	objType

.return:
	rts
; End of function MagicBombObj

; ---------------------------------------------------------------------------
bombSpeedTbl:
	db	-112
	db	-80
	db	-48
	db	-16
	db	16
	db	48
	db	80

; =============== S U B R O U T I N E =======================================


BoundBallObj:
	dec	objTimer
	beq	.erase
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
	bcs	.level3
	lda	#$62
	sta	spriteTileNum
	jsr	DrawObj8x16
	beq	.erase  ; offscreen? erase
	bne	.writeCoords

.level3:
	lda	#$4E
	sta	spriteTileNum
	jsr	DrawObj
	beq	.erase ; offscreen? erase

.writeCoords:
	jsr	WriteProjectileCoords
	bne	.erase  ; hit an object? erase
	rts
; ---------------------------------------------------------------------------

.erase:
	jsr	EraseProjectileCoords
	lda	#OBJ_NONE
	sta	objType
	rts
; End of function BoundBallObj


; =============== S U B R O U T I N E =======================================


ShieldBallObj:
	lda	frameCounter
	and	#3
	bne	.dontDec
	dec	objTimer
	beq	.erase

.dontDec:
	lda	currObjectIndex
	asl	a
	asl	a
	clc
	adc	frameCounter
	pha
	jsr	ShieldBallCos
	clc
	adc	luciaDispX
	sta	spriteX
	pla
	jsr	ShieldBallSin
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

.erase:
	jsr	EraseProjectileCoords
	lda	#OBJ_NONE
	sta	objType
	rts
; End of function ShieldBallObj

; ---------------------------------------------------------------------------

; contains half of 3 different sine curves (other half is mirrored in software)
shieldBallSinTbl:
	db	$00,$08,$0F,$16,$1C,$21,$25,$27,$28,$27,$25,$21,$1C,$16,$0F,$08
	db	$00,$06,$0C,$12,$17,$1B,$1E,$1F,$20,$1F,$1E,$1B,$17,$12,$0C,$06
	db	$00,$05,$09,$0D,$11,$14,$16,$18,$18,$18,$16,$14,$11,$0D,$09,$05

; =============== S U B R O U T I N E =======================================


ShieldBallCos:
	clc
	adc	#8


; =============== S U B R O U T I N E =======================================


ShieldBallSin:
	and	#$1F
	cmp	#$F
	bcs	.negate
	jsr	GetShieldBallOffset
	lda	shieldBallSinTbl,x
	rts
; ---------------------------------------------------------------------------

.negate:
	and	#$F
	jsr	GetShieldBallOffset
	lda	#0
	sec
	sbc	shieldBallSinTbl,x
	rts


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
	bit	objHP	; this gets initialized to 10 by the weapon code
	bpl	.active
	lda	#OBJ_SMASHER_DAMAGE	; have the smasher damage the enemy it homed into after the animation
	sta	objType
	lda	#1
	sta	objTimer
	rts
; ---------------------------------------------------------------------------

.active:
	dec	objTimer
	bne	.timerRemaining
	lda	weaponLevels+5	; higher smasher level = shorter delay
	and	#3
	tax
	lda	smasherDelays,x
	sta	objTimer
	dec	objHP
	bmi	.return

.timerRemaining:
	lda	objHP
	cmp	#6
	bcs	.centerLucia
	jsr	CheckEnemies
	bne	.centerObj
	lda	#OBJ_NONE	; delete smasher object before the "shrink" part of the animation if there's no enemies onscreen
	sta	objType

.return:
	rts
; ---------------------------------------------------------------------------

.centerLucia:
	ldx	#0	; first part of animation: center around Lucia. Otherwise, X is
; initialized to the first enemy object in the objects list

.centerObj:
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

.loop:
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
	bne	.loop
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

.loop:
	lda	objectTable,x
	bne	.return
	txa
	clc
	adc	#$B
	tax
	cmp	#$FD
	bcc	.loop
	lda	#0

.return:
	rts
; End of function CheckEnemies


; =============== S U B R O U T I N E =======================================


SmasherDamageObj:
	lda	objTimer
	beq	.erase
	dec	objTimer
	lda	#0
	sta	dispOffsetX
	lda	#0
	sta	dispOffsetY
	jsr	CalcObjDispPos
	jmp	WriteProjectileCoords
; ---------------------------------------------------------------------------

.erase:
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
	lda	currObjectIndex ; calculate projectile tbl offset
	sec
	sbc	#1
	and	#7
	asl	a
	tax
	ldy	#0
	lda	luciaProjectileCoords+1,x
	cmp	#1  ; set when the projectile hit an enemy
	bne	.noHit
	dey

.noHit:
	lda	spriteX
	sta	luciaProjectileCoords,x
	lda	spriteY
	clc
	adc	#8	; sprites are 8x16 so this gets the center
	cmp	#1
	bne	.not1
	lda	#2

.not1:
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
	beq	.erase
	lda	objTimer
	and	#1
	bne	.return
	lda	#$63
	sta	$0
	lda	#$21
	jsr	GetNextObjSlot
	bne	.return
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

.return:
	rts
; ---------------------------------------------------------------------------

.erase:
	lda	#OBJ_NONE
	sta	objType
	jmp	EraseProjectileCoords
; End of function FlameSwordFlameObj
