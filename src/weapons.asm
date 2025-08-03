; =============== S U B R O U T I N E =======================================


HandleWeapon:
	lda	roomChangeTimer
	bne	locret_D09F
	bit	joy1Edge
	bvc	locret_D09F	; check if B was pressed
	lda	currentWeapon
	tax
	asl	a
	clc
	adc	currentWeapon
	clc
	adc	weaponLevels,x
	tax
	lda	weaponDamageTbl-1,x
	sta	weaponDamage
	ldx	currentWeapon
	beq	handleSword
	dex
	beq	handleFlameSword
	dex
	bne	checkBoundBall
	jmp	handleMagicBomb
; ---------------------------------------------------------------------------

checkBoundBall:
	dex
	bne	checkShieldBall
	jmp	handleBoundBall
; ---------------------------------------------------------------------------

checkShieldBall:
	dex
	bne	checkSmasher
	jmp	handleShieldBall
; ---------------------------------------------------------------------------

checkSmasher:
	dex
	bne	checkFlash
	jmp	handleSmasher
; ---------------------------------------------------------------------------

checkFlash:
	dex
	bne	locret_D09F
	jmp	handleFlash
; ---------------------------------------------------------------------------

locret_D09F:
	rts
; ---------------------------------------------------------------------------
weaponDamageTbl:
	db	$01,$0A,$14
	db	$05,$0A,$14
	db	$02,$08,$0A
	db	$05,$0A,$14
	db	$01,$01,$01
	db	$32,$50,$64
	db	$01,$02,$03
; ---------------------------------------------------------------------------

handleSword:
	lda	attackTimer
	bne	locret_D0BD
	lda	#SFX_SWORD
	bne	loc_D0C7

locret_D0BD:
	rts
; ---------------------------------------------------------------------------

handleFlameSword:
	lda	attackTimer
	bne	locret_D0BD
	jsr	SpawnFlameSwordFlame
	lda	#SFX_FLAME_SWORD

loc_D0C7:
	jsr	PlaySound
	lda	#$B
	sta	attackTimer
	lda	#OBJ_SWORD
	sta	objectTable+$B
	jmp	SubtractWeaponMagic
; ---------------------------------------------------------------------------

handleMagicBomb:
	lda	objectTable+$B	; can't have multiple concurrent magic bombs
	bne	locret_D114
	lda	#0	; copy lucia's object to zero page
	sta	currObjectOffset
	jsr	CopyObjectToZeroPage
	lda	objYPosLo
	sec
	sbc	#$80
	sta	objYPosLo
	bcs	loc_D0ED
	dec	objYPosHi

loc_D0ED:
	lda	#OBJ_MAGIC_BOMB
	sta	objType
	lda	#3
	sta	objTimer
	bit	objDirection
	bmi	loc_D0FD
	lda	#$48
	bne	loc_D0FF

loc_D0FD:
	lda	#$B8

loc_D0FF:
	sta	objXSpeed	; timer was initialized to 3
	lda	#0
	sta	objYSpeed
	lda	#$B
	sta	currObjectOffset
	jsr	CopyZeroPageToObject
	jsr	SubtractWeaponMagic
	lda	#SFX_BOMB
	jmp	PlaySound
; ---------------------------------------------------------------------------

locret_D114:
	rts
; ---------------------------------------------------------------------------

handleBoundBall:
	lda	#0
	sta	currObjectOffset
	jsr	CopyObjectToZeroPage
	lda	#$63
	sta	$0
	lda	#$B
	jsr	GetNextObjSlot
	bne	locret_D176
	stx	currObjectOffset
	lda	objectTable
	cmp	#1
	bne	loc_D136
	lda	directionPressed
	cmp	#5
	beq	loc_D138

loc_D136:
	dec	objYPosHi

loc_D138:
	lda	joy1
	and	#8
	bne	loc_D156
	lda	objDirection
	bmi	loc_D146
	lda	#$7F
	bne	loc_D148

loc_D146:
	lda	#$81

loc_D148:
	sta	objXSpeed
	lda	frameCounter
	and	#$3F
	sec
	sbc	#$20
	sta	objYSpeed
	jmp	loc_D163
; ---------------------------------------------------------------------------

loc_D156:
	lda	#$81
	sta	objYSpeed
	lda	frameCounter
	and	#$3F
	sec
	sbc	#$20
	sta	objXSpeed

loc_D163:
	lda	#OBJ_BOUND_BALL
	sta	objType
	lda	#$64
	sta	objTimer
	jsr	CopyZeroPageToObject
	lda	#SFX_BOUND_BALL
	jsr	PlaySound
	jmp	SubtractWeaponMagic
; ---------------------------------------------------------------------------

locret_D176:
	rts
; ---------------------------------------------------------------------------

handleShieldBall:
	ldx	weaponLevels+4
	lda	shieldBallTbl-1,x
	sta	$0
	ldx	#$58

loc_D180:
	lda	#OBJ_SHIELD_BALL
	sta	objectTable,x	; objType
	lda	$0
	sta	objectTable+2,x	; objTimer
	sec
	sbc	#3
	sta	$0
	txa
	sec
	sbc	#$B
	tax
	bne	loc_D180
	lda	#SFX_SHIELD_BALL
	jsr	PlaySound
	jmp	SubtractWeaponMagic
; ---------------------------------------------------------------------------
shieldBallTbl:
	db	$18,$23,$32
; ---------------------------------------------------------------------------

handleSmasher:
	lda	objectTable+$B
	bne	locret_D1B8
	lda	#OBJ_SMASHER
	sta	objectTable+$B	; type
	lda	#3
	sta	objectTable+$D	; timer
	lda	#$A
	sta	objectTable+$14	; hp
	jmp	SubtractWeaponMagic
; ---------------------------------------------------------------------------

locret_D1B8:
	rts
; ---------------------------------------------------------------------------

handleFlash:
	lda	flashTimer
	bne	locret_D1C9
	lda	#24
	sta	flashTimer
	lda	#SFX_ENEMY_KILL
	jsr	PlaySound
	jmp	SubtractWeaponMagic
; ---------------------------------------------------------------------------

locret_D1C9:
	rts
; End of function HandleWeapon


; =============== S U B R O U T I N E =======================================


SubtractWeaponMagic:
	jsr	MagicSubtract
	jsr	CombineWordDigits
	jsr	MagicSubtract
	bcs	locret_D1D9	; if there's not enough magic to use the weapon again,
				; switch to the basic sword
	lda	#0
	sta	currentWeapon

locret_D1D9:
	rts
; End of function SubtractWeaponMagic


; =============== S U B R O U T I N E =======================================


MagicSubtract:
	lda	currentWeapon

MagicSubtractA:
	asl	a
	tax
	lda	weaponMagicTbl,x
	sta	$0
	lda	weaponMagicTbl+1,x
	sta	$1
	ldx	#0
	jsr	SplitOutWordDigits4
	ldx	#magicLo
	jsr	SplitOutWordDigits
	jsr	BCDSubtract
	ldx	#magicLo
	rts
; End of function MagicSubtract

; ---------------------------------------------------------------------------
weaponMagicTbl:
	dw	0	; sword
	dw	$10	; flame sword
	dw	$20	; magic bomb
	dw	$10	; bound ball
	dw	$150	; shield ball
	dw	$100	; smasher
	dw	$500	; flash
	dw	$1000	; wing of madoola

; =============== S U B R O U T I N E =======================================


SpawnFlameSwordFlame:
	lda	objectTable+$16
	bne	locret_D258
	lda	#$16
	sta	currObjectOffset
	lda	luciaXPosLo
	sta	objXPosLo
	lda	luciaXPosHi
	sta	objXPosHi
	lda	luciaYPosLo
	sta	objYPosLo
	lda	luciaYPosHi
	sta	objYPosHi
	lda	joy1
	and	#4
	bne	loc_D229
	dec	objYPosHi

loc_D229:
	inc	objXPosHi
	lda	#$60
	sta	objXSpeed
	lda	objectTable+$A
	bpl	loc_D23F
	dec	objXPosHi
	dec	objXPosHi
	lda	#0
	sec
	sbc	objXSpeed
	sta	objXSpeed

loc_D23F:
	lda	joy1
	and	#8
	bne	loc_D249
	lda	#0
	beq	loc_D24B

loc_D249:
	lda	#$D0

loc_D24B:
	sta	objYSpeed
	lda	#OBJ_FLAME_SWORD_FLAME
	sta	objType
	lda	#8
	sta	objTimer
	jmp	CopyZeroPageToObject
; ---------------------------------------------------------------------------

locret_D258:
	rts
; End of function SpawnFlameSwordFlame
