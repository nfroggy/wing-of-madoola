; =============== S U B R O U T I N E =======================================


nullsub_1:
	rts
; End of function nullsub_1


; =============== S U B R O U T I N E =======================================


KikuraInitObj:
	lda	objYPosHi
	clc
	adc	#8
	sta	objYPosHi
	lda	#8
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	bit	objDirection	; this gets preset by the enemy spawn code
	bmi	loc_DD7A	; set x speed based on lucia's position when
	lda	#$20		; the kikura spawned (so it moves towards her)
	bne	loc_DD7C

loc_DD7A:
	lda	#$E0

loc_DD7C:
	sta	objXSpeed
	rts
; End of function KikuraInitObj


; =============== S U B R O U T I N E =======================================


KikuraObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_DD8E
	dec	objDirection
	lda	#$CC
	sta	spriteTileNum
	jmp	loc_DDAB
; ---------------------------------------------------------------------------

loc_DD8E:
	lda	objTimer	; every 32 frames, switch between moving up and
	and	#$20		; down and over
	bne	loc_DD9A
	ldx	#$CE		; move up, don't update x pos
	lda	#$E8
	bne	loc_DDA1

loc_DD9A:
	jsr	CalcObjXPos	; move down and over
	ldx	#$CC
	lda	#$10

loc_DDA1:
	stx	!spriteTileNum
	sta	objYSpeed
	jsr	CalcObjYPos
	inc	objTimer

loc_DDAB:
	lda	#3
	sta	spriteAttrs
	jsr	DrawObjNoOffset
	beq	loc_DDBB
	lda	#8
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------

loc_DDBB:
	jmp	EraseObj
; End of function KikuraObj


; =============== S U B R O U T I N E =======================================


NigitoInitObj:
	jsr	PutObjOnFloor
	lda	#$50
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#4
	sta	objTimer
	bit	objDirection
	bmi	loc_DDD8
	lda	#$10
	bne	loc_DDDA

loc_DDD8:
	lda	#$F0

loc_DDDA:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function NigitoInitObj


; =============== S U B R O U T I N E =======================================


NigitoObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_DDE9
	dec	objDirection

loc_DDE9:
	lda	#$3F
	jsr	SpawnFireball
	jsr	HandleObjJump
	bne	loc_DE1E
	jsr	CheckSolidBelow
	beq	loc_DDFE
	jsr	JumpIfHitWall
	jmp	loc_DE1E
; ---------------------------------------------------------------------------

loc_DDFE:
	lda	objTimer
	bne	loc_DE4C
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_DE1E
	lda	#4
	sta	objTimer

loc_DE11:
	lda	#0
	sta	objYSpeed
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	jsr	MoveObjTowardsLucia

loc_DE1E:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_DE49
	lda	#0
	sta	spriteAttrs
	lda	objXPosHi
	and	#1
	beq	loc_DE33
	lda	#$C2
	bne	loc_DE35

loc_DE33:
	lda	#$E2

loc_DE35:
	sta	spriteTileNum
	sec
	sbc	#2
	sta	$0
	jsr	Draw16x32Sprite
	bne	locret_DE48
	lda	#$40
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x32
; ---------------------------------------------------------------------------

locret_DE48:
	rts
; ---------------------------------------------------------------------------

loc_DE49:
	jmp	EraseObj
; ---------------------------------------------------------------------------

loc_DE4C:
	dec	objTimer
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed
	lda	objDirection
	bmi	loc_DE62
	lda	#$80
	ora	objDirection

loc_DE5D:
	sta	objDirection
	jmp	loc_DE11
; ---------------------------------------------------------------------------

loc_DE62:
	lda	#$7F
	and	objDirection
	jmp	loc_DE5D
; End of function NigitoObj


; =============== S U B R O U T I N E =======================================


MantleSkullInitObj:
	jsr	PutObjOnFloor
	lda	#$50
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	bit	objDirection
	bmi	loc_DE83
	lda	#$18
	bne	loc_DE85

loc_DE83:
	lda	#$E8

loc_DE85:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function MantleSkullInitObj

; ---------------------------------------------------------------------------
	jmp	EraseObj

; =============== S U B R O U T I N E =======================================


MantleSkullObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_DE9A
	dec	objDirection
	jmp	loc_DED8
; ---------------------------------------------------------------------------

loc_DE9A:
	lda	#$3F
	jsr	SpawnFireball
	lda	objTimer
	bne	loc_DEB3
	jsr	CheckSolidBelow
	beq	loc_DEAD
	jsr	UpdateObjXPos
	beq	loc_DED8

loc_DEAD:
	lda	#$80
	sta	objYSpeed
	inc	objTimer

loc_DEB3:
	lda	objYSpeed
	bpl	loc_DEC5
	jsr	ApplyGravity
	jsr	UpdateObjYPos
	beq	loc_DED8
	lda	#0
	sta	objYSpeed
	beq	loc_DED8

loc_DEC5:
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_DED8
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	dec	objTimer

loc_DED8:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_DF01
	lda	#0
	sta	spriteAttrs
	lda	objXPosLo
	bmi	loc_DEEB
	lda	#$86
	bne	loc_DEED

loc_DEEB:
	lda	#$A6

loc_DEED:
	sta	spriteTileNum
	sec
	sbc	#2
	sta	$0
	jsr	Draw16x32Sprite
	bne	locret_DF00
	lda	#$40
	sta	objAttackPower
	jsr	CheckIfEnemyHit16x32

locret_DF00:
	rts
; ---------------------------------------------------------------------------

loc_DF01:
	jmp	EraseObj
; End of function MantleSkullObj


; =============== S U B R O U T I N E =======================================


SuneisaInitObj:
	jsr	PutObjOnFloor
	lda	#$80
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	bit	objDirection
	bmi	loc_DF1E
	lda	#$20
	bne	loc_DF20

loc_DF1E:
	lda	#$E0

loc_DF20:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function SuneisaInitObj


; =============== S U B R O U T I N E =======================================


SuneisaObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_DF32
	dec	objDirection
	jmp	loc_DF5E
; ---------------------------------------------------------------------------

loc_DF32:
	lda	objYSpeed
	bne	loc_DF4C
	jsr	CheckSolidBelow
	bne	loc_DF41
	lda	objTimer
	bne	loc_DF4A
	inc	objTimer

loc_DF41:
	jsr	CheckForDrop
	jsr	CheckForHitWall
	jmp	loc_DF5E
; ---------------------------------------------------------------------------

loc_DF4A:
	dec	objTimer

loc_DF4C:
	jsr	ApplyGravity
	jsr	UpdateObjYPos
	beq	loc_DF5E
	lda	#0
	sta	objYSpeed
	lda	objYPosLo
	and	#$80
	sta	objYPosLo

loc_DF5E:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_DF96
	lda	#3
	sta	spriteAttrs
	lda	objXPosLo
	bmi	loc_DF71
	ldy	#2
	bne	loc_DF73

loc_DF71:
	ldy	#4

loc_DF73:
	lda	off_DF99,y
	sta	$0
	lda	off_DF99+1,y
	sta	$1
	ldy	#0
	lda	off_DF99,y
	sta	$4
	lda	off_DF99+1,y
	sta	$5
	jsr	DrawLargeObjNoOffset
	bne	locret_DF95
	lda	#$40
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x32
; ---------------------------------------------------------------------------

locret_DF95:
	rts
; ---------------------------------------------------------------------------

loc_DF96:
	jmp	EraseObj
; End of function SuneisaObj

; ---------------------------------------------------------------------------
off_DF99:
	dw	byte_DF9F
	dw	byte_DFA5
	dw	byte_DFA9
byte_DF9F:
	db	$00
	db	$F0
	db	$10
	db	$10
	db	$F0
	db	$F0
byte_DFA5:
	db	$82
	db	$80
	db	$A2
	db	$00
byte_DFA9:
	db	$CA
	db	$C8
	db	$A0
	db	$00

; =============== S U B R O U T I N E =======================================


ZadoflyInitObj:
	jsr	PutObjOnFloor
	lda	objYPosHi
	sec
	sbc	#2
	sta	objYPosHi
	lda	objMetatile
	sec
	sbc	#$22
	sta	objMetatile
	lda	#$80
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#1
	sta	objTimer
	bit	objDirection
	bmi	loc_DFD5
	lda	#$26
	bne	loc_DFD7

loc_DFD5:
	lda	#$DA

loc_DFD7:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function ZadoflyInitObj

; ---------------------------------------------------------------------------
	jmp	EraseObj

; =============== S U B R O U T I N E =======================================


ZadoflyObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_DFEC
	dec	objDirection
	jmp	loc_E06C
; ---------------------------------------------------------------------------

loc_DFEC:
	lda	objTimer
	bne	loc_E021
	lda	objYSpeed
	bne	loc_E003
	jsr	CheckSolidBelow
	beq	loc_DFFF
	jsr	CheckForHitWall
	jmp	loc_E06C
; ---------------------------------------------------------------------------

loc_DFFF:
	lda	#$80
	sta	objYSpeed

loc_E003:
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	lda	objYSpeed
	bmi	loc_E01E
	lda	#0
	sta	objYSpeed
	lda	#2
	sta	objTimer
	lda	objYPosLo
	and	#$80
	sta	objYPosLo

loc_E01E:
	jmp	loc_E06C
; ---------------------------------------------------------------------------

loc_E021:
	cmp	#2
	bne	loc_E031
	jsr	UpdateObjXPos
	beq	loc_E06C
	lda	#0
	sta	objTimer
	jmp	loc_E06C
; ---------------------------------------------------------------------------

loc_E031:
	lda	objYSpeed
	bne	loc_E055
	lda	objDirection
	bmi	loc_E048
	lda	luciaXPosHi
	sec
	sbc	objXPosHi
	cmp	#5
	bmi	loc_E051

loc_E042:
	jsr	CheckForHitWall
	jmp	loc_E06C
; ---------------------------------------------------------------------------

loc_E048:
	lda	objXPosHi
	sec
	sbc	luciaXPosHi
	cmp	#5
	bpl	loc_E042

loc_E051:
	lda	#0
	sta	objYSpeed

loc_E055:
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_E06C
	lda	#0
	sta	objYSpeed
	sta	objTimer
	lda	objYPosLo
	and	#$80
	sta	objYPosLo

loc_E06C:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_E076
	jmp	loc_E079
; ---------------------------------------------------------------------------

loc_E076:
	jmp	EraseObj
; ---------------------------------------------------------------------------

loc_E079:
	lda	#1
	sta	spriteAttrs
	lda	objTimer
	bne	loc_E08D
	lda	objXPosLo
	bmi	loc_E089
	lda	#$8E
	bne	loc_E08F

loc_E089:
	lda	#$AE
	bne	loc_E08F

loc_E08D:
	lda	#$AE

loc_E08F:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	bne	loc_E099
	jmp	EraseObj
; ---------------------------------------------------------------------------

loc_E099:
	lda	objTimer
	bne	loc_E0A5
	lda	spriteTileNum
	sec
	sbc	#2
	jmp	loc_E0B1
; ---------------------------------------------------------------------------

loc_E0A5:
	lda	objXPosLo
	and	#$40
	bne	loc_E0AF
	lda	#$8C
	bne	loc_E0B1

loc_E0AF:
	lda	#$AC

loc_E0B1:
	sta	spriteTileNum
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	jsr	Write16x16SpriteToOAM
	lda	spriteTileNum
	cmp	#$8C
	bne	loc_E0C7
	lda	#$E8
	bne	loc_E0C9

loc_E0C7:
	lda	#$F8

loc_E0C9:
	sta	spriteTileNum
	lda	objDirection
	bmi	loc_E0E3
	lda	spriteX
	sec
	sbc	#$C
	sta	spriteX
	jsr	WriteSpriteToOAM
	lda	spriteX
	clc
	adc	#$C
	sta	spriteX
	jmp	loc_E0F4
; ---------------------------------------------------------------------------

loc_E0E3:
	lda	spriteX
	clc
	adc	#$C
	sta	spriteX
	jsr	WriteSpriteToOAM
	lda	spriteX
	sec
	sbc	#$C
	sta	spriteX

loc_E0F4:
	lda	#$40
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x32
; End of function ZadoflyObj

; ---------------------------------------------------------------------------
	jmp	EraseObj

; =============== S U B R O U T I N E =======================================


HopeggInitObj:
	jsr	PutObjOnFloor
	lda	#30
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	bit	objDirection
	bmi	loc_E118
	lda	#$20
	bne	loc_E11A

loc_E118:
	lda	#$E0

loc_E11A:
	sta	objXSpeed
	rts
; End of function HopeggInitObj

; ---------------------------------------------------------------------------
	jmp	EraseObj

; =============== S U B R O U T I N E =======================================


HopeggObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_E12B
	dec	objDirection
	jmp	loc_E16A
; ---------------------------------------------------------------------------

loc_E12B:
	lda	objTimer
	cmp	#$A0
	bpl	loc_E136
	inc	objTimer
	jmp	loc_E16A
; ---------------------------------------------------------------------------

loc_E136:
	lda	objTimer
	cmp	#$D0
	beq	loc_E143
	cmp	#$A0
	bne	loc_E149
	jsr	MoveObjTowardsLucia

loc_E143:
	inc	objTimer
	lda	#$80
	sta	objYSpeed

loc_E149:
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_E16A
	jsr	CheckSolidBelow
	beq	loc_E166
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	lda	objTimer
	clc
	adc	#$2F
	sta	objTimer

loc_E166:
	lda	#0
	sta	objYSpeed

loc_E16A:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_E1E8
	lda	#1
	sta	spriteAttrs
	dec	objYPosHi
	lda	#$E8
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	bne	loc_E183
	jmp	EraseObj
; ---------------------------------------------------------------------------

loc_E183:
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	lda	objTimer
	cmp	#$A0
	bpl	loc_E1AD
	and	#$20
	beq	loc_E19D
	lda	objDirection
	and	#$7F
	sta	objDirection
	jmp	loc_E1A3
; ---------------------------------------------------------------------------

loc_E19D:
	lda	objDirection
	ora	#$80
	sta	objDirection

loc_E1A3:
	lda	#$EA
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAM
	jmp	loc_E1D8
; ---------------------------------------------------------------------------

loc_E1AD:
	lda	spriteX
	sec
	sbc	#4
	sta	spriteX
	lda	objDirection
	and	#$7F
	sta	objDirection
	lda	#$FA
	sta	spriteTileNum
	jsr	WriteSpriteToOAMWithDir
	lda	spriteX
	clc
	adc	#8
	sta	spriteX
	lda	objDirection
	ora	#$80
	sta	objDirection
	jsr	WriteSpriteToOAMWithDir
	lda	spriteX
	sec
	sbc	#4
	sta	spriteX

loc_E1D8:
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	inc	objYPosHi
	lda	#$25
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x32
; ---------------------------------------------------------------------------

loc_E1E8:
	jmp	EraseObj
; End of function HopeggObj


; =============== S U B R O U T I N E =======================================


SpajyanInitObj:
	jsr	PutObjOnFloor
	lda	#3
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	bit	objDirection
	bmi	loc_E205
	lda	#8
	bne	loc_E207

loc_E205:
	lda	#$F8

loc_E207:
	sta	objXSpeed
	lda	#$80
	sta	objYSpeed
	rts
; End of function SpajyanInitObj

; ---------------------------------------------------------------------------
	jmp	EraseObj

; =============== S U B R O U T I N E =======================================


SpajyanObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_E21C
	dec	objDirection
	jmp	loc_E259
; ---------------------------------------------------------------------------

loc_E21C:
	lda	objTimer
	beq	loc_E22B
	jsr	CheckForDrop
	jsr	CheckForHitWall
	inc	objTimer
	jmp	loc_E259
; ---------------------------------------------------------------------------

loc_E22B:
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	CheckForHitWall
	jsr	CheckForHitWall
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_E259
	jsr	CheckSolidBelow
	bne	loc_E248
	lda	#0
	beq	loc_E257

loc_E248:
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	lda	objTimer
	clc
	adc	#$80
	sta	objTimer
	lda	#$80

loc_E257:
	sta	objYSpeed

loc_E259:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_E282
	lda	#3
	sta	spriteAttrs
	lda	objTimer
	beq	loc_E272
	lda	objXPosLo
	and	#$40
	beq	loc_E272
	lda	#$8A
	bne	loc_E274

loc_E272:
	lda	#$AA

loc_E274:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_E282
	lda	#8
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------

loc_E282:
	jmp	EraseObj
; End of function SpajyanObj


; =============== S U B R O U T I N E =======================================


YokkoChanInitObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	keywordDisplayFlag
	bne	loc_E2AC
	jsr	PutObjOnFloor
	lda	#1
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#2
	sta	objTimer
	bit	objDirection
	bmi	loc_E2A3
	lda	#$C
	bne	loc_E2A5

loc_E2A3:
	lda	#$F4

loc_E2A5:
	sta	objXSpeed
	lda	#$B0
	sta	objYSpeed
	rts
; ---------------------------------------------------------------------------

loc_E2AC:
	jmp	EraseObj
; End of function YokkoChanInitObj


; =============== S U B R O U T I N E =======================================


YokkoChanObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_E2BA
	dec	objDirection
	jmp	loc_E2F9
; ---------------------------------------------------------------------------

loc_E2BA:
	jsr	UpdateRNG	; randomly play chirping sound
	and	#$1F
	bne	loc_E2C6
	lda	#SFX_YOKKO_CHAN
	jsr	PlaySound

loc_E2C6:
	lda	objTimer
	beq	loc_E2D7
	jsr	CheckForDrop
	jsr	CheckForHitWall
	inc	objTimer
	inc	objTimer
	jmp	loc_E2F9
; ---------------------------------------------------------------------------

loc_E2D7:
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_E2F9
	jsr	CheckSolidBelow
	bne	loc_E2EB
	lda	#0	; don't jump if not on ground
	beq	loc_E2F7

loc_E2EB:
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	inc	objTimer
	inc	objTimer
	lda	#$B0	; jump

loc_E2F7:
	sta	objYSpeed

loc_E2F9:
	jsr	GetObjMetatile
	cmp	#$1F	; erase object if inside a wall?
	bcc	loc_E329
	lda	#0
	sta	spriteAttrs
	lda	objTimer
	beq	loc_E312
	lda	objXPosLo
	and	#$40
	beq	loc_E312
	lda	#$AC
	bne	loc_E314

loc_E312:
	lda	#$8C

loc_E314:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_E329
	lda	#$FF
	sta	objAttackPower
	jsr	CheckIfEnemyHit16x16
	bne	locret_E328
	lda	#$FF
	sta	keywordDisplayFlag

locret_E328:
	rts
; ---------------------------------------------------------------------------

loc_E329:
	jmp	EraseObj
; End of function YokkoChanObj


; =============== S U B R O U T I N E =======================================


DopipuInitObj:
	jsr	PutObjOnFloor
	lda	#7
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	bit	objDirection
	bmi	loc_E346
	lda	#$10
	bne	loc_E348

loc_E346:
	lda	#$F0

loc_E348:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function DopipuInitObj

; ---------------------------------------------------------------------------
	jmp	EraseObj

; =============== S U B R O U T I N E =======================================


DopipuObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_E35D
	dec	objDirection
	jmp	loc_E396
; ---------------------------------------------------------------------------

loc_E35D:
	lda	objTimer
	bne	loc_E371
	jsr	CheckSolidBelow
	beq	loc_E36B
	jsr	UpdateObjXPos
	beq	loc_E396

loc_E36B:
	lda	#$80
	sta	objYSpeed
	inc	objTimer

loc_E371:
	lda	objYSpeed
	bpl	loc_E383
	jsr	ApplyGravity
	jsr	UpdateObjYPos
	beq	loc_E396
	lda	#0
	sta	objYSpeed
	beq	loc_E396

loc_E383:
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_E396
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	dec	objTimer

loc_E396:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_E3C7
	lda	#1
	sta	spriteAttrs
	lda	objTimer
	bne	loc_E3AF
	lda	objXPosLo
	bmi	loc_E3B7
	lda	objXPosHi
	and	#1
	bne	loc_E3B3

loc_E3AF:
	lda	#$A8
	bne	loc_E3B9

loc_E3B3:
	lda	#$AA
	bne	loc_E3B9

loc_E3B7:
	lda	#$CA

loc_E3B9:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_E3C7
	lda	#$10
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------

loc_E3C7:
	jmp	EraseObj
; End of function DopipuObj


; =============== S U B R O U T I N E =======================================


NishigaInitObj:
	lda	#8
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	bit	objDirection
	bmi	loc_E3E1
	lda	#$20
	bne	loc_E3E3

loc_E3E1:
	lda	#$E0

loc_E3E3:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function NishigaInitObj


; =============== S U B R O U T I N E =======================================


NishigaObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_E3F5
	dec	objDirection
	jmp	loc_E421
; ---------------------------------------------------------------------------

loc_E3F5:
	lda	objTimer
	and	#$20
	bne	loc_E3FF
	lda	#$F0
	bne	loc_E41A

loc_E3FF:
	lda	objTimer
	and	#$40
	bne	loc_E409
	lda	#$10
	bne	loc_E41A

loc_E409:
	lda	objTimer
	and	#$1F
	bne	loc_E412
	jsr	MoveObjTowardsLucia

loc_E412:
	jsr	CheckForHitWall
	inc	!objTimer
	lda	#$20

loc_E41A:
	sta	objYSpeed
	jsr	UpdateObjYPos
	inc	objTimer

loc_E421:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_E446
	lda	#2
	sta	spriteAttrs
	lda	objTimer
	and	#2
	beq	loc_E436
	lda	#$88
	bne	loc_E438

loc_E436:
	lda	#$A8

loc_E438:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_E446
	lda	#8
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------

loc_E446:
	jmp	EraseObj
; End of function NishigaObj


; =============== S U B R O U T I N E =======================================


NyuruInitObj:
	lda	#$A
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	rts
; End of function NyuruInitObj


; =============== S U B R O U T I N E =======================================


NyuruObj:

; FUNCTION CHUNK AT E4EF SIZE 0000003A BYTES
; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	#2
	sta	$0	; this gets used as a flag to see if the nyuru is on top of lucia
	lda	objDirection
	and	#$7F
	beq	loc_E468
	dec	objDirection
	jmp	loc_E4F4
; ---------------------------------------------------------------------------

loc_E468:
	lda	objXPosHi
	sec
	sbc	luciaXPosHi
	beq	nyuruXEqualCoarse	; branch if on top of lucia
	bcs	nyuruRightCoarse	; branch if to the right of lucia
	lda	luciaXPosHi	; to the left of lucia
	sec
	sbc	objXPosHi
	jsr	MulBy8
	bne	setNyuruXSpeed

nyuruRightCoarse:
	jsr	MulBy8
	eor	#$FF	; negate the number
	clc
	adc	#1
	bne	setNyuruXSpeed

nyuruXEqualCoarse:
	lda	objXPosLo
	sec
	sbc	luciaXPosLo
	beq	nyuruXEqualFine
	bcs	nyuruRightFine
	lda	luciaXPosLo
	sec
	sbc	objXPosLo
	lsr	a
	bne	setNyuruXSpeed

nyuruRightFine:
	lsr	a
	eor	#$FF
	clc
	adc	#1
	bne	setNyuruXSpeed

nyuruXEqualFine:
	dec	$0	; decrement "equal pos" flag
	lda	#0

setNyuruXSpeed:
	sta	objXSpeed
	lda	objYPosHi
	clc
	adc	#1
	sec
	sbc	luciaYPosHi
	beq	nyuruYEqualCoarse
	bcs	nyuruBelowCoarse
	lda	luciaYPosHi
	sec
	sbc	#1
	sec
	sbc	objYPosHi
	jsr	MulBy8
	bne	setNyuruYSpeed

nyuruBelowCoarse:
	jsr	MulBy8
	eor	#$FF
	clc
	adc	#1
	bne	setNyuruYSpeed

nyuruYEqualCoarse:
	lda	objYPosLo
	sec
	sbc	!luciaYPosLo
	beq	nyuruYEqualFine
	bcs	nyuruBelowFine
	lda	luciaYPosLo
	sec
	sbc	!objYPosLo
	lsr	a
	bne	setNyuruYSpeed

nyuruBelowFine:
	lsr	a
	eor	#$FF
	clc
	adc	#1
	bne	setNyuruYSpeed

nyuruYEqualFine:
	dec	$0	; decrement "equal pos" flag: it should be 0 if both x and y are equal
	lda	#0

setNyuruYSpeed:
	sta	objYSpeed
	jmp	loc_E4EF
; End of function NyuruObj


; =============== S U B R O U T I N E =======================================


MulBy8:
	asl	a
	asl	a
	asl	a
	rts
; End of function MulBy8

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR NyuruObj

loc_E4EF:
	jsr	CalcObjXYPos
	inc	objTimer

loc_E4F4:
	lda	#1
	sta	spriteAttrs
	lda	$0
	bne	loc_E502	; if not on top, use a different frame
	lda	objTimer
	beq	loc_E516
	bne	loc_E512

loc_E502:
	lda	objTimer	; "regular movement" animation code
	and	#$10
	beq	loc_E516
	lda	objTimer
	and	#$20
	beq	loc_E512
	lda	#$4E
	bne	loc_E518

loc_E512:
	lda	#$AE
	bne	loc_E518

loc_E516:
	lda	#$8E

loc_E518:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_E526	; despawn if nyuru is offscreen
	lda	#$20	; attack points (bcd)
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------

loc_E526:
	jmp	EraseObj
; END OF FUNCTION CHUNK FOR NyuruObj

; =============== S U B R O U T I N E =======================================


BiforceInitObj:
	jsr	PutObjOnFloor
	lda	#$FF
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#$54
	sta	objTimer
	lda	objDirection
	bmi	loc_E543
	lda	#$10
	bne	loc_E545

loc_E543:
	lda	#$F0

loc_E545:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function BiforceInitObj


; =============== S U B R O U T I N E =======================================


BiforceObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_E554
	dec	objDirection

loc_E554:
	lda	objHP
	cmp	#$80
	bcs	loc_E55D
	jmp	loc_E678
; ---------------------------------------------------------------------------

loc_E55D:
	lda	objTimer
	bmi	loc_E598
	and	#$40
	beq	loc_E5AF
	jsr	CheckForHitWall
	dec	objTimer
	lda	objTimer
	and	#$3F
	bne	loc_E586
	jsr	MoveObjTowardsLucia
	lda	#$3F
	sta	objTimer
	lda	objDirection
	bmi	loc_E57F
	lda	#$F0
	bne	loc_E581

loc_E57F:
	lda	#$10

loc_E581:
	sta	objXSpeed
	jmp	loc_E5C4
; ---------------------------------------------------------------------------

loc_E586:
	lda	objDirection
	bmi	loc_E58E
	lda	#4
	bne	loc_E590

loc_E58E:
	lda	#$FC

loc_E590:
	clc
	adc	objXSpeed
	sta	objXSpeed
	jmp	loc_E5C4
; ---------------------------------------------------------------------------

loc_E598:
	lda	#$F
	jsr	SpawnFireball
	jsr	MoveObjTowardsLucia
	dec	objTimer
	lda	objTimer
	and	#$3F
	bne	loc_E5C4
	lda	#$54
	sta	objTimer
	jmp	loc_E5C4
; ---------------------------------------------------------------------------

loc_E5AF:
	jsr	CheckForHitWall
	dec	objTimer
	lda	objTimer
	and	#$3F
	bne	loc_E5C4
	lda	#$BF
	sta	objTimer
	jmp	loc_E5C4
; ---------------------------------------------------------------------------

loc_E5C1:
	jmp	EraseObj
; ---------------------------------------------------------------------------

loc_E5C4:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_E5C1
	lda	#2
	sta	!spriteAttrs
	lda	objTimer
	and	#8
	bne	loc_E5DA
	ldy	#2
	bne	loc_E5DC

loc_E5DA:
	ldy	#4

loc_E5DC:
	lda	off_E65C,y
	sta	$0
	lda	off_E65C+1,y
	sta	$1
	ldy	#0
	lda	off_E65C,y
	sta	$4
	lda	off_E65C+1,y
	sta	$5
	jsr	DrawLargeObjNoOffset
	bne	loc_E5C1
	lda	objTimer
	and	#8
	bne	loc_E601
	lda	#$80
	bne	loc_E603

loc_E601:
	lda	#$D0

loc_E603:
	sta	spriteTileNum
	jsr	WriteSpriteToOAM
	inc	!spriteTileNum
	inc	!spriteTileNum
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	jsr	WriteSpriteToOAM
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	lda	objDirection
	bmi	loc_E627
	lda	#$E8
	bne	loc_E629

loc_E627:
	lda	#$18

loc_E629:
	clc
	adc	spriteX
	sta	spriteX
	lda	objTimer
	and	#4
	bne	loc_E638
	lda	#$B4
	bne	loc_E63A

loc_E638:
	lda	#$84

loc_E63A:
	sta	spriteTileNum
	jsr	WriteSpriteToOAM
	lda	spriteY
	sec
	sbc	#$20
	sta	spriteY
	lda	objDirection
	bmi	loc_E64E
	lda	#$C
	bne	loc_E650

loc_E64E:
	lda	#$E4

loc_E650:
	clc
	adc	spriteX
	sta	spriteX
	lda	#$80
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x32
; ---------------------------------------------------------------------------
off_E65C:
	dw	byte_E662
	dw	byte_E66C
	dw	byte_E672
byte_E662:
	db	$00
	db	$F0
	db	$00
	db	$F0
	db	$10
	db	$00
	db	$00
	db	$10
	db	$E4
	db	$F0
byte_E66C:
	db	$94
	db	$92
	db	$90
	db	$B0
	db	$B2
	db	$00
byte_E672:
	db	$94
	db	$92
	db	$90
	db	$E0
	db	$E2
	db	$00
; ---------------------------------------------------------------------------

loc_E678:
	lda	objTimer
	bmi	loc_E6B9
	and	#$40
	bne	loc_E6ED
	lda	objTimer
	lda	#$F
	jsr	SpawnFireball
	ldy	#2
	lda	objYPosHi
	sec
	sbc	luciaYPosHi

loc_E68E:
	bcs	loc_E695
	eor	#$FF	; if number is negative, negate it so it's positive
	clc
	adc	#1

loc_E695:
	asl	a
	asl	a
	asl	a
	asl	a
	cmp	#$10
	bcs	loc_E69F
	lda	#8

loc_E69F:
	dey
	beq	loc_E6CB
	sta	objYSpeed
	lda	objYPosHi
	cmp	luciaYPosHi
	bcc	loc_E6B1
	lda	#0
	sec
	sbc	objYSpeed
	sta	objYSpeed

loc_E6B1:
	lda	objXPosHi
	sec
	sbc	luciaXPosHi
	jmp	loc_E68E
; ---------------------------------------------------------------------------

loc_E6B9:
	dec	objTimer
	lda	objTimer
	and	#$7F
	bne	loc_E6C5
	lda	#$30
	sta	objTimer

loc_E6C5:
	jsr	MoveObjTowardsLucia
	jmp	loc_E712
; ---------------------------------------------------------------------------

loc_E6CB:
	tay
	lda	objDirection
	bmi	loc_E6D4
	tya
	jmp	loc_E6DA
; ---------------------------------------------------------------------------

loc_E6D4:
	tya
	eor	#$FF
	clc
	adc	#1

loc_E6DA:
	sta	objXSpeed
	dec	objTimer
	bne	loc_E6E4
	lda	#$68
	sta	objTimer

loc_E6E4:
	jsr	MoveObjTowardsLucia

loc_E6E7:
	jsr	CalcObjXYPos
	jmp	loc_E712
; ---------------------------------------------------------------------------

loc_E6ED:
	lda	objDirection
	bmi	loc_E6F5
	lda	#$E0
	bne	loc_E6F7

loc_E6F5:
	lda	#$20

loc_E6F7:
	sta	objXSpeed
	lda	#$E8
	sta	objYSpeed
	dec	objTimer
	lda	objTimer
	and	#$3F
	bne	loc_E6E7
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed
	lda	#$C0
	sta	objTimer
	bne	loc_E6E7

loc_E712:
	lda	#2
	sta	!spriteAttrs
	jsr	LimitObjDistance
	lda	objXPosHi
	and	#1
	bne	loc_E724
	ldy	#2
	bne	loc_E726

loc_E724:
	ldy	#4

loc_E726:
	lda	off_E77F,y
	sta	$0
	lda	off_E77F+1,y
	sta	$1
	ldy	#0
	lda	off_E77F,y
	sta	$4
	lda	off_E77F+1,y
	sta	$5
	jsr	DrawLargeObjNoOffset
	bne	loc_E77A
	lda	objXPosHi
	and	#1
	bne	loc_E74B
	lda	#$82
	bne	loc_E74D

loc_E74B:
	lda	#$D2

loc_E74D:
	sta	spriteTileNum
	jsr	WriteSpriteToOAM
	dec	!spriteTileNum
	dec	!spriteTileNum
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	jsr	WriteSpriteToOAM
	lda	objDirection
	bmi	loc_E76A
	lda	#$F4
	bne	loc_E76C

loc_E76A:
	lda	#$C

loc_E76C:
	clc
	adc	!spriteX
	sta	!spriteX
	lda	#$80
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x32
; ---------------------------------------------------------------------------

loc_E77A:
	lda	#0
	sta	objType
	rts
; End of function BiforceObj

; ---------------------------------------------------------------------------
off_E77F:
	dw	byte_E785
	dw	byte_E78D
	dw	byte_E792
byte_E785:
	db	$00
	db	$F0
	db	$10
	db	$00
	db	$00
	db	$10
	db	$E4
	db	$00
byte_E78D:
	db	$AE
	db	$90
	db	$B0
	db	$B2
	db	$00
byte_E792:
	db	$AE
	db	$90
	db	$E0
	db	$E2
	db	$00

; =============== S U B R O U T I N E =======================================


BospidoInitObj:
	jsr	PutObjOnFloor
	lda	#$FF
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	lda	objDirection
	bmi	loc_E7B1
	lda	#$30
	bne	loc_E7B3

loc_E7B1:
	lda	#$D0

loc_E7B3:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function BospidoInitObj


; =============== S U B R O U T I N E =======================================


BospidoObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_E7C2
	dec	objDirection

loc_E7C2:
	lda	#$F
	jsr	SpawnFireball
	lda	objYSpeed
	bne	loc_E7E1
	inc	objTimer
	lda	objTimer
	cmp	#$40
	bne	loc_E7FF
	lda	#0
	sta	objTimer
	lda	#$80
	sta	objYSpeed
	jsr	MoveObjTowardsLucia
	jmp	loc_E7FF
; ---------------------------------------------------------------------------

loc_E7E1:
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_E7FF
	lda	#0
	sta	objYSpeed
	lda	#$80
	and	objYPosLo
	sta	objYPosLo
	jsr	MoveObjTowardsLucia
	jmp	loc_E7FF
; ---------------------------------------------------------------------------

loc_E7FC:
	jmp	EraseObj
; ---------------------------------------------------------------------------

loc_E7FF:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_E7FC
	lda	#2
	sta	spriteAttrs
	lda	objTimer
	and	#8
	bne	loc_E814
	ldy	#4
	bne	loc_E816

loc_E814:
	ldy	#2

loc_E816:
	lda	off_E877,y
	sta	$0
	lda	off_E877+1,y
	sta	$1
	ldy	#0
	lda	off_E877,y
	sta	$4
	lda	off_E877+1,y
	sta	$5
	jsr	DrawLargeObjNoOffset
	bne	loc_E7FC
	lda	objTimer
	and	#8
	bne	loc_E83B
	lda	#$FA
	bne	loc_E83D

loc_E83B:
	lda	#$CA

loc_E83D:
	sta	spriteTileNum
	jsr	WriteSpriteToOAM
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	dec	spriteTileNum
	dec	spriteTileNum
	jsr	WriteSpriteToOAM
	lda	objDirection
	bpl	loc_E85C
	lda	spriteX
	sec
	sbc	#$1C
	jmp	loc_E861
; ---------------------------------------------------------------------------

loc_E85C:
	lda	spriteX
	clc
	adc	#$1C

loc_E861:
	sta	spriteX
	lda	objTimer
	and	#8
	beq	loc_E870
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY

loc_E870:
	lda	#$80
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; End of function BospidoObj

; ---------------------------------------------------------------------------
off_E877:
	dw	byte_E87D
	dw	byte_E885
	dw	byte_E88A
byte_E87D:
	db	$F0
	db	$00
	db	$00
	db	$F0
	db	$10
	db	$00
	db	$0C
	db	$10
byte_E885:
	db	$AA
	db	$8A
	db	$88
	db	$A8
	db	$00
byte_E88A:
	db	$8E
	db	$DA
	db	$D8
	db	$8C
	db	$00

; =============== S U B R O U T I N E =======================================


JoyraimaInitObj:
	jsr	PutObjOnFloor
	lda	#SFX_JOYRAIMA
	jsr	PlaySound
	lda	#$C0
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	lda	objDirection
	bmi	loc_E8AE
	lda	#4
	bne	loc_E8B0

loc_E8AE:
	lda	#$FC

loc_E8B0:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function JoyraimaInitObj


; =============== S U B R O U T I N E =======================================


JoyraimaObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_E8BF
	dec	objDirection

loc_E8BF:
	inc	objTimer
	lda	objDirection
	bmi	loc_E8C9
	lda	#1
	bne	loc_E8CB

loc_E8C9:
	lda	#$FF

loc_E8CB:
	clc
	adc	objXSpeed
	bmi	loc_E909
	cmp	#$38
	bcc	loc_E8D6
	lda	#$38

loc_E8D6:
	sta	objXSpeed
	lda	objXPosHi
	cmp	luciaXPosHi
	bcc	loc_E8E4
	lda	objDirection
	ora	#$80
	bne	loc_E8E8

loc_E8E4:
	lda	objDirection
	and	#$7F

loc_E8E8:
	sta	objDirection
	jsr	CheckForHitWall
	jsr	CheckSolidBelow
	bne	loc_E914
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed
	lda	objDirection
	bmi	loc_E901
	ora	#$80
	bne	loc_E903

loc_E901:
	and	#$7F

loc_E903:
	sta	!objDirection
	jmp	loc_E914
; ---------------------------------------------------------------------------

loc_E909:
	cmp	#$C8
	bcs	loc_E8D6
	lda	#$C8
	bne	loc_E8D6

loc_E911:
	jmp	EraseObj
; ---------------------------------------------------------------------------

loc_E914:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_E911
	lda	#0
	sta	spriteAttrs
	lda	objTimer
	and	#4
	bne	loc_E929
	lda	#$86
	bne	loc_E92B

loc_E929:
	lda	#$C6

loc_E92B:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_E911
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	dec	spriteTileNum
	dec	spriteTileNum
	jsr	Write16x16SpriteToOAM
	ldy	#0
	lda	objDirection
	bmi	loc_E948
	ldy	#2

loc_E948:
	lda	byte_E97F,y
	clc
	adc	spriteX
	sta	spriteX
	iny
	lda	spriteTileNum
	clc
	adc	#$20
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAM
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	inc	spriteTileNum
	inc	spriteTileNum
	jsr	Write16x16SpriteToOAM
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	lda	byte_E97F,y
	clc
	adc	spriteX
	sta	spriteX
	lda	#$60
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x32
; End of function JoyraimaObj

; ---------------------------------------------------------------------------
byte_E97F:
	db	$10
	db	$F0
	db	$F0
	db	$10

; =============== S U B R O U T I N E =======================================


GaguzulInitObj:
	jsr	PutObjOnFloor
	lda	#$C0
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	lda	objDirection
	bmi	loc_E99D
	lda	#$18
	bne	loc_E99F

loc_E99D:
	lda	#$E8

loc_E99F:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function GaguzulInitObj


; =============== S U B R O U T I N E =======================================


GaguzulObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_E9AE
	dec	objDirection

loc_E9AE:
	lda	#$1F
	jsr	SpawnFireball
	inc	objTimer
	lda	objTimer
	and	#$1F
	bne	loc_E9BE
	jsr	MoveObjTowardsLucia

loc_E9BE:
	jsr	HandleObjJump
	bne	loc_E9EC
	jsr	CheckSolidBelow
	beq	loc_E9CE
	jsr	JumpIfHitWall
	jmp	loc_E9EC
; ---------------------------------------------------------------------------

loc_E9CE:
	jsr	ApplyGravity
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_E9EC
	lda	#0
	sta	objYSpeed
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	jsr	MoveObjTowardsLucia
	jmp	loc_E9EC
; ---------------------------------------------------------------------------

loc_E9E9:
	jmp	EraseObj
; ---------------------------------------------------------------------------

loc_E9EC:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_E9E9
	lda	#3
	sta	spriteAttrs
	lda	objXPosHi
	and	#1
	bne	loc_EA01
	lda	#$C2
	bne	loc_EA03

loc_EA01:
	lda	#$C6

loc_EA03:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_E9E9
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	dec	spriteTileNum
	dec	spriteTileNum
	jsr	Write16x16SpriteToOAM
	ldy	#0
	lda	objDirection
	bmi	loc_EA20
	ldy	#2

loc_EA20:
	lda	byte_EA57,y
	clc
	adc	spriteX
	sta	spriteX
	iny
	lda	spriteTileNum
	clc
	adc	#$20
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAM
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	inc	spriteTileNum
	inc	spriteTileNum
	jsr	Write16x16SpriteToOAM
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	lda	byte_EA57,y
	clc
	adc	spriteX
	sta	spriteX
	lda	#$60
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x32
; End of function GaguzulObj

; ---------------------------------------------------------------------------
byte_EA57:
	db	$10
	db	$F0
	db	$F0
	db	$10

; =============== S U B R O U T I N E =======================================


NipataInitObj:
	jsr	nullsub_2
	lda	#5
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#$5E
	sta	objTimer
	bmi	loc_EA73	; bug? forgot to load objDirection
	lda	#$20
	bne	loc_EA75

loc_EA73:
	lda	#$E0

loc_EA75:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function NipataInitObj


; =============== S U B R O U T I N E =======================================


NipataObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_EA87
	dec	objDirection

loc_EA84:
	jmp	loc_EB14
; ---------------------------------------------------------------------------

loc_EA87:
	lda	objTimer
	and	#$C0
	bne	loc_EAA8
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_EA84
	lda	#0
	sta	objYSpeed
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	lda	objTimer
	ora	#$8F
	sta	objTimer
	jmp	loc_EB14
; ---------------------------------------------------------------------------

loc_EAA8:
	and	#$40
	beq	loc_EAE6
	jsr	CheckForHitWall
	jsr	ApplyGravity
	jsr	UpdateObjYPos
	bne	loc_EAE0
	lda	objTimer
	and	#$30
	cmp	#$30
	beq	loc_EAC1
	dec	objTimer

loc_EAC1:
	dec	objTimer
	lda	objTimer
	and	#$F
	beq	loc_EACC
	jmp	loc_EB14
; ---------------------------------------------------------------------------

loc_EACC:
	lda	#$F8
	sta	objYSpeed

loc_EAD0:
	lda	objTimer
	and	#$3F
	clc
	adc	#$10
	sta	objTimer
	and	#$40
	bne	loc_EAD0
	jmp	loc_EB14
; ---------------------------------------------------------------------------

loc_EAE0:
	lda	#$F0
	sta	objYSpeed
	bne	loc_EAD0

loc_EAE6:
	jsr	UpdateRNG
	and	#1
	bne	loc_EB14
	dec	objTimer
	lda	objTimer
	and	#$F
	bne	loc_EB14
	lda	objTimer
	ora	#$4E
	and	#$7F
	sta	objTimer
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed
	lda	objDirection
	bmi	loc_EB0C
	ora	#$80
	bne	loc_EB0E

loc_EB0C:
	and	#$7F

loc_EB0E:
	sta	objDirection
	lda	#0
	sta	objYSpeed

loc_EB14:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_EB6A
	lda	#0
	sta	spriteAttrs
	lda	objTimer
	bmi	loc_EB2D
	lda	objXPosHi
	and	#1
	bne	loc_EB2D
	lda	#$80
	bne	loc_EB2F

loc_EB2D:
	lda	#$90

loc_EB2F:
	sta	spriteTileNum
	lda	objDirection
	ora	#$80
	sta	objDirection
	jsr	DrawObj8x16NoOffset
	beq	loc_EB6A
	lda	objDirection
	and	#$7F
	sta	objDirection
	lda	spriteX
	clc
	adc	#8
	sta	spriteX
	jsr	WriteSpriteToOAMWithDir
	lda	objXSpeed
	bpl	loc_EB56
	lda	objDirection
	ora	#$80
	bne	loc_EB5A

loc_EB56:
	lda	objDirection
	and	#$7F

loc_EB5A:
	sta	objDirection
	lda	spriteX
	sec
	sbc	#8
	sta	spriteX
	lda	#8
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------

loc_EB6A:
	jmp	EraseObj
; End of function NipataObj


; =============== S U B R O U T I N E =======================================


PeraSkullInitObj:
	jsr	nullsub_2
	lda	#25
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#$4C
	sta	objTimer
	lda	objDirection
	bmi	loc_EB87
	lda	#$10
	bne	loc_EB89

loc_EB87:
	lda	#$F0

loc_EB89:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function PeraSkullInitObj


; =============== S U B R O U T I N E =======================================


PeraSkullObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_EB9B
	dec	objDirection
	jmp	loc_EBF0
; ---------------------------------------------------------------------------

loc_EB9B:
	lda	objTimer
	beq	loc_EBD8
	and	#$80
	bne	loc_EBC5
	jsr	CheckForHitWall
	jsr	ApplyGravity
	jsr	UpdateObjYPos
	beq	loc_EBB2
	lda	#$F0
	bne	loc_EBBC

loc_EBB2:
	dec	objTimer
	lda	objTimer
	and	#$3F
	bne	loc_EBF0
	lda	#$F0

loc_EBBC:
	sta	objYSpeed
	lda	#0
	sta	objTimer
	jmp	loc_EBF0
; ---------------------------------------------------------------------------

loc_EBC5:
	dec	objTimer
	lda	objTimer
	and	#$3F
	bne	loc_EBF0
	lda	#$4C
	sta	objTimer
	lda	#0
	sta	objYSpeed
	jmp	loc_EBF0
; ---------------------------------------------------------------------------

loc_EBD8:
	jsr	CheckForHitWall
	jsr	UpdateObjYPos
	beq	loc_EBF0
	lda	#0
	sta	objYSpeed
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	lda	#$9F
	sta	objTimer
	bne	loc_EBF0

loc_EBF0:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_EC29
	lda	#1
	sta	!spriteAttrs
	lda	objTimer
	bmi	loc_EC19
	lda	objXPosLo
	and	#$70
	bne	loc_EC0B
	lda	#SFX_PERASKULL
	jsr	PlaySound

loc_EC0B:
	lda	objXPosLo
	and	#$40
	bne	loc_EC15
	lda	#$88
	bne	loc_EC1B

loc_EC15:
	lda	#$8A
	bne	loc_EC1B

loc_EC19:
	lda	#$EA

loc_EC1B:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_EC29
	lda	#$20
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------

loc_EC29:
	jmp	EraseObj
; End of function PeraSkullObj


; =============== S U B R O U T I N E =======================================


FireInitObj:
	jsr	PutObjOnFloor
	lda	#$23
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#0
	sta	objTimer
	lda	objDirection
	bmi	loc_EC46
	lda	#8
	bne	loc_EC48

loc_EC46:
	lda	#$F8

loc_EC48:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	rts
; End of function FireInitObj


; =============== S U B R O U T I N E =======================================


FireObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	objDirection
	and	#$7F
	beq	loc_EC5A
	dec	objDirection
	jmp	loc_ECAD
; ---------------------------------------------------------------------------

loc_EC5A:
	lda	objYSpeed
	bne	loc_EC70
	jsr	UpdateObjXPos
	bne	loc_EC88
	lda	objTimer
	and	#$3F
	sta	objTimer
	jsr	CheckSolidBelow
	bne	loc_ECAD
	beq	loc_EC73

loc_EC70:
	jsr	CheckForHitWall

loc_EC73:
	jsr	ApplyGravity
	jsr	UpdateObjYPos
	beq	loc_ECAD
	lda	#0
	sta	objYSpeed
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	jmp	loc_ECAD
; ---------------------------------------------------------------------------

loc_EC88:
	lda	objTimer
	clc
	adc	#$40
	sta	objTimer
	and	#$C0
	beq	loc_ECA9
	lda	objDirection
	bmi	loc_EC9B
	ora	#$80
	bne	loc_EC9D

loc_EC9B:
	and	#$7F

loc_EC9D:
	sta	objDirection
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed
	jmp	loc_ECAD
; ---------------------------------------------------------------------------

loc_ECA9:
	lda	#$80
	sta	objYSpeed

loc_ECAD:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_ED02
	lda	#0
	sta	spriteAttrs
	inc	objTimer
	lda	objTimer
	and	#$3F
	bne	loc_ECC7
	lda	objTimer
	sec
	sbc	#$40
	sta	objTimer

loc_ECC7:
	and	#$1C
	lsr	a
	lsr	a
	tay
	lda	byte_ECFA,y
	sta	dispOffsetY
	lda	#0
	sta	dispOffsetX
	lda	#$C8
	sta	spriteTileNum
	jsr	DrawObj
	beq	loc_ED02
	lda	#$A0
	sta	spriteTileNum
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	jsr	Write16x16SpriteToOAM
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	lda	#$25
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------
byte_ECFA:
	db	$00
	db	$FD
	db	$FB
	db	$FD
	db	$00
	db	$03
	db	$05
	db	$03
; ---------------------------------------------------------------------------

loc_ED02:
	jmp	EraseObj
; End of function FireObj


; =============== S U B R O U T I N E =======================================


HyperEyemonInitObj:
	jsr	PutObjOnFloor
	lda	#$12
	sta	objHP
	lda	#OBJ_EYEMON
	sta	objType
	lda	objDirection
	bmi	loc_ED18
	lda	#$20
	bne	loc_ED1A

loc_ED18:
	lda	#$E0

loc_ED1A:
	sta	objXSpeed
	lda	#$20
	sta	objYSpeed
	lda	#0
	sta	objTimer
	rts
; End of function HyperEyemonInitObj


; =============== S U B R O U T I N E =======================================


EyemonInitObj:
	jsr	PutObjOnFloor
	lda	#$A
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	objDirection
	bmi	loc_ED3B
	lda	#$10
	bne	loc_ED3D

loc_ED3B:
	lda	#$F0

loc_ED3D:
	sta	objXSpeed
	lda	#$10
	sta	objYSpeed
	lda	#0
	sta	objTimer
	rts
; End of function EyemonInitObj


; =============== S U B R O U T I N E =======================================


EyemonObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	#0
	sta	spriteAttrs
	lda	objDirection
	and	#$7F
	beq	loc_ED57
	dec	objDirection
	jmp	loc_EDDF
; ---------------------------------------------------------------------------

loc_ED57:
	lda	objTimer
	and	#$40
	bne	loc_ED98
	lda	objTimer
	and	#$80
	bne	loc_EDAB
	jsr	UpdateObjXPos
	bne	loc_ED8A
	lda	objTimer
	beq	loc_ED72
	dec	!objTimer
	jmp	loc_EDDF
; ---------------------------------------------------------------------------

loc_ED72:
	jsr	CheckSolidBelow
	bne	loc_ED95
	jsr	UpdateObjYPos
	bne	loc_EDDF
	lda	#$DF
	sta	objTimer
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed
	jmp	loc_EDDF
; ---------------------------------------------------------------------------

loc_ED8A:
	lda	#$DF
	sta	objTimer
	lda	#0
	sec
	sbc	objYSpeed
	sta	objYSpeed

loc_ED95:
	jmp	loc_EDDF
; ---------------------------------------------------------------------------

loc_ED98:
	dec	objTimer
	lda	objTimer
	and	#$3F
	bne	loc_ED95
	lda	objTimer
	and	#$80
	ora	#7
	sta	objTimer
	jmp	loc_EDDF
; ---------------------------------------------------------------------------

loc_EDAB:
	jsr	UpdateObjYPos
	bne	loc_EDD4
	lda	objTimer
	and	#$7F
	beq	loc_EDBB
	dec	objTimer
	jmp	loc_EDDF
; ---------------------------------------------------------------------------

loc_EDBB:
	jsr	UpdateObjXPos
	bne	loc_EDDF
	lda	#7
	sta	objTimer
	lda	#0
	sec
	sbc	objYSpeed
	sta	objYSpeed
	bpl	loc_EDCF
	lda	#$80

loc_EDCF:
	sta	spriteAttrs
	jmp	loc_EDDF
; ---------------------------------------------------------------------------

loc_EDD4:
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed
	lda	#0
	sta	objTimer

loc_EDDF:
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_EE3A
	lda	objYSpeed
	bpl	loc_EDEF
	lda	#0
	sec
	sbc	objYSpeed

loc_EDEF:
	cmp	#$10
	bne	loc_EDF7
	lda	#3
	bne	loc_EDF9

loc_EDF7:
	lda	#0

loc_EDF9:
	ora	spriteAttrs
	sta	spriteAttrs
	lda	objXSpeed
	bmi	loc_EE08
	lda	objDirection
	and	#$7F
	jmp	loc_EE0C
; ---------------------------------------------------------------------------

loc_EE08:
	lda	objDirection
	ora	#$80

loc_EE0C:
	sta	objDirection
	lda	objTimer
	and	#$C0
	bne	loc_EE18
	lda	#$CC
	bne	loc_EE1A

loc_EE18:
	lda	#$CE

loc_EE1A:
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_EE3A
	lda	!objYSpeed
	bpl	loc_EE2B
	lda	#0
	sec
	sbc	objYSpeed

loc_EE2B:
	cmp	#$10
	bne	loc_EE33
	lda	#$10
	bne	loc_EE35

loc_EE33:
	lda	#$18

loc_EE35:
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------

loc_EE3A:
	jmp	EraseObj
; End of function EyemonObj


; =============== S U B R O U T I N E =======================================

; Keeps the object's X pos within 6 metatiles of Lucia's

LimitObjDistance:
	lda	objXPosHi
	sec
	sbc	luciaXPosHi
	bcs	loc_EE63	; branch if object is to the right of lucia
	eor	#$FF		; negate the number (two's compliment) to make it positive
	clc
	adc	#1
	cmp	#6
	bcc	locret_EE62	; return if difference is less than 6 metatiles
	bne	loc_EE55	; branch if the distance is greater than 6 metatiles
	lda	luciaXPosLo	; return if distance is equal to 6 metatiles and lucia's x pos is
	cmp	objXPosLo	; less than the object's (this is effectively rounding)
	bcc	locret_EE62

loc_EE55:
	lda	luciaXPosLo	; limit distance to just under 6 metatiles
	sec
	sbc	#$FF
	sta	objXPosLo
	lda	luciaXPosHi
	sbc	#5
	sta	objXPosHi

locret_EE62:
	rts
; ---------------------------------------------------------------------------

loc_EE63:
	cmp	#6
	bcc	locret_EE62	; return if difference is less than 6 metatiles
	bne	loc_EE6F	; branch if the distance is greater than 6 metatiles
	lda	objXPosLo	; return if distance is equal to 6 metatiles and object's x pos is
	cmp	luciaXPosLo	; less than lucia's (this is effectively rounding)
	bcc	locret_EE62

loc_EE6F:
	lda	luciaXPosLo	; limit distance to just under 6 metatiles
	clc
	adc	#$FF
	sta	objXPosLo
	lda	luciaXPosHi
	adc	#5
	sta	objXPosHi
	rts
; End of function LimitObjDistance


; =============== S U B R O U T I N E =======================================

; If the object hits a wall, make it jump

JumpIfHitWall:
	jsr	UpdateObjXPos
	beq	locret_EE86
	lda	#$80
	sta	objYSpeed

locret_EE86:
	rts
; End of function JumpIfHitWall


; =============== S U B R O U T I N E =======================================


HandleObjJump:
	lda	objYSpeed
	beq	locret_EEA6	; return if not in the air
	jsr	ApplyGravity
	lda	objYSpeed
	bmi	loc_EE95
	jsr	CheckForHitWall

loc_EE95:
	jsr	UpdateObjYPos
	beq	loc_EEA4
	lda	#0	; if the object hit the ground, make its y speed 0
	sta	objYSpeed
	lda	objYPosLo	; and align it to the metatile grid
	and	#$80
	sta	objYPosLo

loc_EEA4:
	lda	#$FF

locret_EEA6:
	rts
; End of function HandleObjJump


; =============== S U B R O U T I N E =======================================

; spriteTileNum: lower sprite tile
; $0: upper sprite tile

Draw16x32Sprite:
	jsr	DrawObjNoOffset
	beq	loc_EEBD
	lda	$0
	sta	spriteTileNum
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	jsr	Write16x16SpriteToOAM
	lda	#0
	rts
; ---------------------------------------------------------------------------

loc_EEBD:
	lda	#0
	sta	!objType
	lda	#$FF
	rts
; End of function Draw16x32Sprite


; =============== S U B R O U T I N E =======================================

; draw large object
; $0: pointer to tile number array
; $4: pointer to position offset array

DrawLargeObj:
	ldy	#0
	sty	$3	; cursor
	lda	(0),y	; $0: tile number array
	sta	spriteTileNum
	jsr	DrawObj
	beq	loc_EF1F
	jmp	loc_EEF0
; End of function DrawLargeObj


; =============== S U B R O U T I N E =======================================

; draw large object, absolute
; $0: pointer to tile number array
; $4: pointer to position offset array

DrawLargeObjAbs:
	ldy	#0
	sty	$3	; cursor
	lda	(0),y	; tile number array
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAM
	jmp	loc_EEF0
; End of function DrawLargeObjAbs


; =============== S U B R O U T I N E =======================================

; draw large object, without a display offset
; $0: pointer to tile number array
; $4: pointer to position offset array

DrawLargeObjNoOffset:
	ldy	#0
	sty	$3	; cursor
	lda	(0),y	; tile number array
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_EF1F

loc_EEF0:
	tya
	asl	a	; multiply by 2: offset array is x offset, y offset
	tay
	lda	objDirection
	bmi	loc_EF00
	lda	spriteX	; subtract the x offset if object is facing right
	sec
	sbc	(4),y	; $4: position offset array
	jmp	loc_EF05
; ---------------------------------------------------------------------------

locret_EEFF:
	rts
; ---------------------------------------------------------------------------

loc_EF00:
	lda	spriteX	; add the x offset if object is facing left
	clc
	adc	(4),y	; $4: position offset array

loc_EF05:
	sta	spriteX
	iny
	lda	spriteY	; add the y offset
	clc
	adc	(4),y
	sta	spriteY
	inc	$3	; increment & restore the (non-multiplied by 2) cursor value
	ldy	$3
	lda	(0),y
	beq	locret_EEFF	; if tile number is 0, exit the loop
	sta	spriteTileNum	; otherwise, write the next tile
	jsr	Write16x16SpriteToOAM
	jmp	loc_EEF0
; ---------------------------------------------------------------------------

loc_EF1F:
	lda	#0
	sta	objType
	lda	#$FF
	rts
; End of function DrawLargeObjNoOffset


; =============== S U B R O U T I N E =======================================


DarutosInitObj:
	lda	#$3A	; darutos's position is hardcoded
	sta	objXPosHi
	lda	#$1F
	sta	objYPosHi
	lda	#$80
	sta	objXPosLo
	sta	objYPosLo
	lda	#$FF
	sta	objHP
	lda	objType
	clc
	adc	#$20
	sta	objType
	lda	#$2F
	sta	objTimer
	lda	#$80
	sta	objDirection
	lda	#$E0
	sta	objXSpeed
	lda	#$38
	sta	objYSpeed
	rts
; End of function DarutosInitObj


; =============== S U B R O U T I N E =======================================


DarutosObj:
	lda	objDirection
	and	#$7F
	beq	loc_EF58
	dec	objDirection

loc_EF58:
	lda	objTimer
	and	#$20
	bne	loc_EFB8
	lda	objTimer
	and	#$BF
	sta	objTimer
	and	#$10
	bne	loc_EFC1
	jsr	CalcObjXPos
	jsr	CalcObjYPos
	jsr	UpdateRNG
	and	#3
	bne	loc_EF83
	lda	objTimer	; why not just do eor #$80?
	bmi	loc_EF7D
	ora	#$80
	bne	loc_EF7F

loc_EF7D:
	and	#$7F

loc_EF7F:
	and	#$BF
	sta	objTimer

loc_EF83:
	dec	objTimer
	lda	objTimer
	and	#$F
	beq	loc_EF8E
	jmp	loc_F00D
; ---------------------------------------------------------------------------

loc_EF8E:
	lda	objYSpeed
	bmi	loc_EFAD
	lda	objDirection
	bmi	loc_EF9A
	ora	#$80
	bne	loc_EF9C

loc_EF9A:
	and	#$7F

loc_EF9C:
	sta	objDirection
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed
	lda	objTimer
	ora	#$2F
	sta	objTimer
	bne	loc_EFB3

loc_EFAD:
	lda	objTimer
	ora	#$1F
	and	#$DF

loc_EFB3:
	sta	objTimer
	jmp	loc_F00D
; ---------------------------------------------------------------------------

loc_EFB8:
	lda	objTimer
	ora	#$40
	sta	objTimer
	jmp	loc_EFD5
; ---------------------------------------------------------------------------

loc_EFC1:
	jsr	CalcObjXPos
	lda	objYPosHi
	sta	dispOffsetY
	dec	objYPosHi
	dec	objYPosHi
	lda	#7
	jsr	SpawnFireball
	lda	dispOffsetY
	sta	objYPosHi

loc_EFD5:
	jsr	UpdateRNG
	and	#3
	bne	loc_EFF6
	lda	objTimer
	and	#$F
	cmp	#5
	bcc	loc_EFEA
	lda	objTimer
	and	#$10
	beq	loc_EFF6

loc_EFEA:
	lda	objTimer
	bmi	loc_EFF2
	ora	#$80
	bne	loc_EFF4

loc_EFF2:
	and	#$7F

loc_EFF4:
	sta	objTimer

loc_EFF6:
	dec	objTimer
	lda	objTimer
	and	#$F
	bne	loc_F00D
	lda	#0
	sec
	sbc	objYSpeed
	sta	objYSpeed
	lda	objTimer
	and	#$C0
	ora	#$F
	sta	objTimer

loc_F00D:
	lda	#2
	sta	spriteAttrs
	lda	#0
	sta	dispOffsetY
	sta	dispOffsetX
	lda	objTimer
	and	#$40
	bne	loc_F02D
	lda	objDirection
	bmi	loc_F025
	lda	#$F0
	bne	loc_F027

loc_F025:
	lda	#$10

loc_F027:
	sta	dispOffsetX
	ldy	#4
	bne	loc_F02F

loc_F02D:
	ldy	#2

loc_F02F:
	lda	off_F147,y
	sta	$0
	lda	off_F147+1,y
	sta	$1
	lda	off_F147
	sta	$4
	lda	off_F147+1
	sta	$5
	ldy	#0
	sty	$3
	lda	(0),y
	sta	spriteTileNum
	jsr	DrawObj
	beq	locret_F07E
	jsr	loc_EEF0
	lda	spriteY
	sta	$F
	iny
	lda	(0),y
	sta	spriteTileNum
	lda	objTimer
	and	#$40
	beq	loc_F07F
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	lda	objDirection
	bmi	loc_F071
	lda	#$FC
	bne	loc_F073

loc_F071:
	lda	#4

loc_F073:
	clc
	adc	spriteX
	sta	spriteX
	jsr	Write16x16SpriteToOAM
	jmp	loc_F082
; ---------------------------------------------------------------------------

locret_F07E:
	rts
; ---------------------------------------------------------------------------

loc_F07F:
	jsr	WriteSpriteToOAM

loc_F082:
	lda	$F
	sec
	sbc	#$20
	sta	spriteY
	lda	objTimer
	and	#$40
	beq	loc_F093
	lda	#$E8
	bne	loc_F095

loc_F093:
	lda	#$E4

loc_F095:
	ldy	objDirection
	bmi	loc_F09E
	eor	#$FF
	clc
	adc	#1

loc_F09E:
	clc
	adc	spriteX
	sta	spriteX
	lda	objTimer
	bmi	loc_F0AB
	ldy	#8
	bne	loc_F0AD

loc_F0AB:
	ldy	#$A

loc_F0AD:
	lda	off_F147,y
	sta	$0
	lda	off_F147+1,y
	sta	$1
	ldy	#6
	lda	off_F147,y
	sta	$4
	lda	off_F147+1,y
	sta	$5
	jsr	DrawLargeObjAbs
	iny
	lda	(0),y
	sta	spriteTileNum
	jsr	WriteSpriteToOAM
	iny
	lda	(0),y
	sta	spriteTileNum
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	jsr	WriteSpriteToOAM
	lda	objXPosHi
	and	#1
	bne	loc_F0E7
	lda	#$80
	bne	loc_F0E9

loc_F0E7:
	lda	#$88

loc_F0E9:
	sta	spriteTileNum
	lda	objDirection
	bmi	loc_F0F3
	lda	#$28
	bne	loc_F0F5

loc_F0F3:
	lda	#$D8

loc_F0F5:
	clc
	adc	spriteX
	sta	spriteX
	jsr	WriteSpriteToOAM
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	lda	objXPosLo
	bmi	loc_F10C
	lda	#$82
	bne	loc_F10E

loc_F10C:
	lda	#$8A

loc_F10E:
	sta	spriteTileNum
	jsr	WriteSpriteToOAM
	lda	spriteTileNum
	clc
	adc	#$10
	sta	spriteTileNum
	lda	objDirection
	bmi	loc_F122
	lda	#$F4
	bne	loc_F124

loc_F122:
	lda	#$C

loc_F124:
	clc
	adc	spriteX
	sta	spriteX
	jsr	Write16x16SpriteToOAM
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	lda	#$95
	sta	objAttackPower
	jsr	CheckIfEnemyHit16x16
	bne	locret_F146
	dec	orbCollectedFlag
	jsr	PlayRoomSong
	lda	#SFX_BOSS_KILL
	jmp	PlaySound
; ---------------------------------------------------------------------------

locret_F146:
	rts
; End of function DarutosObj

; ---------------------------------------------------------------------------
off_F147:
	dw	byte_F153
	dw	byte_F15B
	dw	byte_F161
	dw	byte_F167
	dw	byte_F16D
	dw	byte_F173
byte_F153:
	db	$F0
	db	$00
	db	$00
	db	$F0
	db	$10
	db	$00
	db	$0C
	db	$00
byte_F15B:
	db	$A6
	db	$86
	db	$84
	db	$A4
	db	$00
	db	$C6
byte_F161:
	db	$BE
	db	$9E
	db	$9C
	db	$BC
	db	$00
	db	$DC
byte_F167:
	db	$10
	db	$00
	db	$00
	db	$10
	db	$0C
	db	$00
byte_F16D:
	db	$90
	db	$B0
	db	$B2
	db	$00
	db	$D2
	db	$D0
byte_F173:
	db	$98
	db	$B8
	db	$BA
	db	$00
	db	$DA
	db	$D8
; ---------------------------------------------------------------------------

EraseObj:
	lda	#0
	sta	objType
	rts

; =============== S U B R O U T I N E =======================================


BunyonInitObj:
	jsr	PutObjOnFloor
	lda	#$A0
	sta	!objHP
	inc	objType
	lda	objDirection
	bmi	loc_F190
	lda	#$14
	bne	loc_F192

loc_F190:
	lda	#$EC

loc_F192:
	sta	objXSpeed
	lda	#0
	sta	objYSpeed
	lda	#0
	sta	objTimer
	rts
; End of function BunyonInitObj


; =============== S U B R O U T I N E =======================================


MedBunyonInitObj:
	lda	#$50
	sta	objHP
	inc	objType
	lda	#0
	sta	objYSpeed
	sta	objTimer
	jmp	InitObjectCollision
; End of function MedBunyonInitObj


; =============== S U B R O U T I N E =======================================


SmallBunyonInitObj:
	lda	#$20
	sta	objHP
	inc	objType
	lda	#0
	sta	objYSpeed
	sta	objTimer
	jmp	InitObjectCollision
; End of function SmallBunyonInitObj


; =============== S U B R O U T I N E =======================================


BunyonObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	bossActiveFlag
	beq	loc_F207
	jsr	HandleBunyonMovement
	jsr	GetObjMetatile
	cmp	#$1F
	bcc	loc_F207
	lda	#2
	sta	spriteAttrs
	lda	off_F20A
	sta	$4
	lda	off_F20A+1
	sta	$5
	lda	off_F20C
	sta	$0
	lda	off_F20C+1
	sta	$1
	lda	#0
	sta	dispOffsetY
	ldy	#0
	lda	objDirection
	bmi	loc_F1ED
	ldy	#$F0

loc_F1ED:
	sty	!dispOffsetX
	jsr	DrawLargeObj
	bne	loc_F207
	lda	#$35
	sta	objAttackPower
	jsr	CheckIfEnemyHit16x16
	bne	locret_F206
	lda	#OBJ_BUNYON_SPLIT
	sta	objType
	lda	#$10
	sta	objTimer

locret_F206:
	rts
; ---------------------------------------------------------------------------

loc_F207:
	jmp	EraseObj
; End of function BunyonObj

; ---------------------------------------------------------------------------
off_F20A:
	dw	unk_F20E
off_F20C:
	dw	unk_F216
unk_F20E:
	db	$F0
	db	$00
	db	$00
	db	$F0
	db	$10
	db	$00
	db	$F8
	db	$10
unk_F216:
	db	$E6
	db	$C6
	db	$C4
	db	$E4
	db	$00

; =============== S U B R O U T I N E =======================================


MedBunyonObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	bossActiveFlag
	beq	loc_F23D
	jsr	HandleBunyonMovement
	lda	#2
	sta	spriteAttrs
	lda	#$A6
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	beq	loc_F23D
	lda	#$18
	sta	objAttackPower
	jsr	CheckIfEnemyHit16x16
	bne	locret_F23C
	lda	#OBJ_MED_BUNYON_SPLIT
	sta	objType

locret_F23C:
	rts
; ---------------------------------------------------------------------------

loc_F23D:
	jmp	EraseObj
; End of function MedBunyonObj


; =============== S U B R O U T I N E =======================================


SmallBunyonObj:

; FUNCTION CHUNK AT F179 SIZE 00000005 BYTES

	lda	bossActiveFlag
	beq	loc_F25C
	jsr	HandleBunyonMovement
	lda	#2
	sta	spriteAttrs
	lda	#$AC
	sta	spriteTileNum
	jsr	DrawObj8x16NoOffset
	beq	loc_F25C
	lda	#$12
	sta	objAttackPower
	jmp	CheckIfEnemyHit16x16
; ---------------------------------------------------------------------------
	rts
; ---------------------------------------------------------------------------

loc_F25C:
	jmp	EraseObj
; End of function SmallBunyonObj


; =============== S U B R O U T I N E =======================================


BunyonSplitObj:
	dec	objTimer
	bne	loc_F270
	ldy	#0
	lda	#$2C
	sta	$1
	lda	#$18
	sta	$2
	jmp	HandleBunyonSplit
; ---------------------------------------------------------------------------

loc_F270:
	lda	#$80
	sta	objDirection
	lda	#$CE
	sta	spriteTileNum
	lda	#$CC
	sta	$0
	jsr	Draw16x32Sprite
	bne	loc_F29D
	lda	#0
	sta	objDirection
	lda	spriteX
	clc
	adc	#$10
	sta	spriteX
	jsr	Write16x16SpriteToOAMWithDir
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	lda	#$CE
	sta	spriteTileNum
	jmp	Write16x16SpriteToOAMWithDir

loc_F29D:
	lda	#0
	sta	objType
	rts
; End of function BunyonSplitObj


; =============== S U B R O U T I N E =======================================


MedBunyonSplitObj:
	dec	objTimer
	beq	loc_F2B4
	lda	#$86
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	bne	locret_F2B3
	lda	#0
	sta	objType

locret_F2B3:
	rts
; ---------------------------------------------------------------------------

loc_F2B4:
	ldy	#$18
	lda	#$B
	sta	$1
	lda	currObjectIndex
	cmp	#$15
	bne	loc_F2C4
	lda	#$24
	bne	loc_F2C6

loc_F2C4:
	lda	#$30

loc_F2C6:
	sta	$2
	jmp	HandleBunyonSplit
; End of function MedBunyonSplitObj


; =============== S U B R O U T I N E =======================================


HandleBunyonMovement:
	inc	objTimer
	lda	objDirection
	and	#$7F
	beq	loc_F2D5
	dec	objDirection

loc_F2D5:
	jsr	CheckForHitWall
	jsr	ApplyGravity
	jsr	UpdateObjYPos
	beq	locret_F2F0
	jsr	UpdateRNG
	and	#$E0
	sta	objYSpeed
	lda	objYPosLo
	and	#$80
	sta	objYPosLo
	jmp	MoveObjTowardsLucia
; ---------------------------------------------------------------------------

locret_F2F0:
	rts
; End of function HandleBunyonMovement


; =============== S U B R O U T I N E =======================================
;
;  y: Offset in bunyon split table
; $1: Value to add to go to the next object slot (this lets the code skip over slots)
; $2: end offset in split table

HandleBunyonSplit:
	lda	bossActiveFlag
	bne	loc_F2F8
	jmp	EraseObj
; ---------------------------------------------------------------------------

loc_F2F8:
	lda	currObjectIndex	; multiply currObjectIndex by 11 (size of an object slot)
; to get the offset
	asl	a
	asl	a
	asl	a
	sta	$0
	lda	currObjectIndex
	asl	a
	clc
	adc	$0
	clc
	adc	currObjectIndex
	sta	!$3
	tax

loc_F30C:
	lda	objXPosLo
	clc
	adc	bunyonSplitTbl,y
	sta	objectTable+8,x	; x pos lo
	iny
	lda	objXPosHi
	adc	bunyonSplitTbl,y
	sta	objectTable+7,x	; x pos hi
	iny
	lda	objYPosLo
	clc
	adc	bunyonSplitTbl,y
	sta	objectTable+6,x	; y pos lo
	iny
	lda	objYPosHi
	adc	bunyonSplitTbl,y
	sta	objectTable+5,x	; y pos hi
	iny
	lda	bunyonSplitTbl,y
	sta	objectTable+$A,x	; direction
	iny
	lda	bunyonSplitTbl,y
	sta	objectTable+4,x	; x speed
	lda	objType
	sta	objectTable,x	; type
	inc	objectTable,x
	lda	objMetatile
	sta	objectTable+1,x	; metatile
	txa
	clc
	adc	$1
	tax
	iny
	cpy	$2
	bne	loc_F30C
	inc	objType
	ldx	$3
	lda	objectTable+8,x
	sta	objXPosLo
	lda	objectTable+7,x
	sta	objXPosHi
	lda	objectTable+6,x
	sta	objYPosLo
	lda	objectTable+5,x
	sta	objYPosHi
	lda	objectTable+$A,x
	sta	objDirection
	lda	objectTable+4,x
	sta	objYSpeed
	lda	objectTable+1,x
	sta	objMetatile
	rts
; End of function HandleBunyonSplit

; ---------------------------------------------------------------------------
bunyonSplitTbl:
	db	$00,$FF,$00,$FF,$80,$E8
	db	$00,$FF,$00,$00,$80,$E8
	db	$00,$00,$00,$FF,$00,$18
	db	$00,$00,$00,$00,$00,$18
	db	$BF,$FF,$BF,$FF,$80,$E4
	db	$BF,$FF,$00,$00,$80,$E4
	db	$00,$00,$BF,$FF,$00,$1C
	db	$00,$00,$00,$00,$00,$1C
