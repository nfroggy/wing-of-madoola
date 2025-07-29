; =============== S U B R O U T I N E =======================================

; Limits Lucia's current HP/MP to whatever her
; max is, and limits her max to 5000

LimitLuciaHPMP:
	lda	maxMagicHi
	cmp	#$50	; 'P'
	bcc	loc_BD76
	lda	#0
	sta	maxMagicLo
	lda	#$50	; 'P'
	sta	maxMagicHi

loc_BD76:
	lda	healthLo
	cmp	maxHealthLo
	lda	healthHi
	sbc	maxHealthHi
	bcc	loc_BD88
	lda	maxHealthLo
	sta	healthLo
	lda	maxHealthHi
	sta	healthHi

loc_BD88:
	lda	maxHealthHi
	cmp	#$50
	bcc	loc_BD96
	lda	#0
	sta	maxHealthLo
	lda	#$50
	sta	maxHealthHi

loc_BD96:
	lda	magicLo
	cmp	maxMagicLo
	lda	magicHi
	sbc	maxMagicHi
	bcc	locret_BDA8
	lda	maxMagicLo
	sta	magicLo
	lda	maxMagicHi
	sta	magicHi

locret_BDA8:
	rts
; End of function LimitLuciaHPMP


; =============== S U B R O U T I N E =======================================


DeleteAllObjectsButLucia:
	lda	#$B

DeleteAllObjectsAfterA:
	tax
	lda	#0
	sta	objectTable,x
	txa
	clc
	adc	#$B
	bcc	DeleteAllObjectsAfterA
	rts
; End of function DeleteAllObjectsButLucia


; =============== S U B R O U T I N E =======================================


HandleRoomChange:
	lda	vramWriteCount
	bne	locret_BDEF
	lda	roomChangeTimer
	beq	locret_BDEF
	lda	objectTable
	cmp	#OBJ_LUCIA_LVL_END_DOOR		; is lucia's object an "end of level door" object?
	bne	loc_BDED			; if not, just decrement the timer
	lda	roomChangeTimer			; if it is, use the timer to do the "end of level door" animation
	cmp	#$FF
	beq	locret_BDEF
	cmp	#60
	beq	leftDoorOpen1
	cmp	#59
	beq	rightDoorOpen1
	cmp	#45
	beq	leftDoorOpen2
	cmp	#44
	beq	rightDoorOpen2
	cmp	#30
	beq	leftDoorOpen1
	cmp	#29
	beq	rightDoorOpen1
	cmp	#15
	beq	leftDoorClose
	cmp	#14
	beq	rightDoorClose

loc_BDED:
	dec	roomChangeTimer

locret_BDEF:
	rts
; ---------------------------------------------------------------------------

leftDoorOpen2:
	ldy	#$30
	bne	leftDoor

rightDoorOpen2:
	ldy	#$30
	bne	rightDoor

leftDoorOpen1:
	ldy	#$18
	bne	leftDoor

rightDoorOpen1:
	ldy	#$24
	bne	rightDoor

leftDoorClose:
	ldy	#0
	beq	leftDoor

rightDoorClose:
	ldy	#$C
	bne	rightDoor
; End of function HandleRoomChange


; =============== S U B R O U T I N E =======================================


GetDoorVramAddr:
	lda	luciaXPosHi
	asl	a
	and	#$F8
	clc
	adc	#2
	sec
	sbc	cameraXTiles
	clc
	adc	nametablePosX
	sta	$0
	lda	luciaYPosHi
	asl	a
	and	#$F8
	clc
	adc	#2
	sec
	sbc	cameraYTiles
	clc
	adc	nametablePosY
	sta	$1
	jmp	CalcVRAMWriteAddr
; End of function GetDoorVramAddr

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR HandleRoomChange

rightDoor:
	jsr	GetDoorVramAddr
	jsr	IncVramTileCol
	jsr	IncVramTileCol
	jmp	loc_BE3A
; ---------------------------------------------------------------------------

leftDoor:
	jsr	GetDoorVramAddr

loc_BE3A:
	lda	#6
	sta	tmpCount

loc_BE3E:
	jsr	VramWriteLinear
	lda	doorAnimTbl,y
	iny
	sta	vramWriteBuff,x
	inx
	lda	doorAnimTbl,y
	iny
	sta	vramWriteBuff,x
	inx
	stx	vramWriteCount
	jsr	VramSetWriteCount
	jsr	IncVramTileRow
	dec	tmpCount
	bne	loc_BE3E
	jmp	loc_BDED
; END OF FUNCTION CHUNK FOR HandleRoomChange
; ---------------------------------------------------------------------------
doorAnimTbl:
	db	$D5
	db	$D6
	db	$E5
	db	$E6
	db	$E7
	db	$E8
	db	$E5
	db	$E6
	db	$E7
	db	$E8
	db	$F5
	db	$F6
	db	$D7
	db	$D8
	db	$E7
	db	$E8
	db	$E5
	db	$E6
	db	$E7
	db	$E8
	db	$E5
	db	$E6
	db	$F5
	db	$F6
	db	$D6
	db	$FF
	db	$E6
	db	$FF
	db	$E8
	db	$FF
	db	$E6
	db	$FF
	db	$E8
	db	$FF
	db	$F6
	db	$FF
	db	$FF
	db	$D7
	db	$FF
	db	$E7
	db	$FF
	db	$E5
	db	$FF
	db	$E7
	db	$FF
	db	$E5
	db	$FF
	db	$F5
	db	$FF
	db	$FF
	db	$FF
	db	$FF
	db	$FF
	db	$FF
	db	$FF
	db	$FF
	db	$FF
	db	$FF
	db	$FF
	db	$FF

; =============== S U B R O U T I N E =======================================


DisplayHUDNumSprites:
	lda	#3
	sta	tmpCount
	ldy	tmpCount

loc_BEA2:
	lda	0,y
	asl	a	; multiply number by 2 to get tile num offset
	clc
	adc	#$6C	; add tile number of "0" number
	sta	0,y
	dey
	bpl	loc_BEA2
	lda	#0
	sta	tmpPtrLo
	sta	tmpPtrHi
	ldy	tmpCount

loc_BEB7:
	lda	(tmpPtrLo),y
	beq	loc_BEC0
	sta	spriteTileNum
	jsr	WriteSpriteToOAM

loc_BEC0:
	lda	spriteX
	clc
	adc	#8
	sta	spriteX
	dey
	bpl	loc_BEB7
	rts
; End of function DisplayHUDNumSprites


; =============== S U B R O U T I N E =======================================


DisplayHealth:
	ldx	#healthLo
	lda	#$70
	sta	spriteX
	lda	#$10
	sta	spriteY
	lda	#3	; palette #7

loc_BED7:
	sta	spriteAttrs
	jsr	SplitOutWordDigits
	jsr	DisplayHUDNumSprites
	lda	#$5C	; draw the borders on either side of the numbers
	sta	spriteTileNum
	lda	#$68
	sta	spriteX
	jsr	WriteSpriteToOAM
	lda	#$90
	sta	spriteX
	lda	spriteAttrs
	ora	#$40
	sta	spriteAttrs
	jmp	WriteSpriteToOAM
; End of function DisplayHealth

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR DisplayHealthAndMagic

DisplayMagic:
	ldx	#magicLo
	lda	#$70
	sta	spriteX
	lda	#$D0
	sta	spriteY
	lda	#0	; palette #4
	beq	loc_BED7
; END OF FUNCTION CHUNK FOR DisplayHealthAndMagic

; =============== S U B R O U T I N E =======================================


DisplayHealthAndMagic:

; FUNCTION CHUNK AT BEF7 SIZE 0000000E BYTES

	jsr	DisplayHealth
	jmp	DisplayMagic
; End of function DisplayHealthAndMagic


; =============== S U B R O U T I N E =======================================

; In: X - Address of zero-page word to read from
; Writes each digit individually, lowest in $00 and highest in $03
; (aka it reads backwards)

SplitOutWordDigits:
	ldy	#0
	beq	loc_BF11
; End of function SplitOutWordDigits


; =============== S U B R O U T I N E =======================================

; In: X - Address of zero-page word to read from
; Writes each digit individually, lowest in $04 and highest in $07
; (aka it reads backwards)

SplitOutWordDigits4:
	ldy	#4

loc_BF11:
	jsr	SplitOutWordDigitsInternal
	inx	; fall through to the internal subroutine
; End of function SplitOutWordDigits4


; =============== S U B R O U T I N E =======================================


SplitOutWordDigitsInternal:
	lda	0,x
	and	#$F
	sta	0,y
	iny
	lda	0,x
	jsr	ShiftRight4
	sta	0,y
	iny
	rts
; End of function SplitOutWordDigitsInternal


; =============== S U B R O U T I N E =======================================

; In: Individual hex digits in little-endian order at $0-$3
; Out: Combined word (little-endian) at $0-$1

CombineWordDigits:
	ldy	#0
	jsr	CombineWordDigitsInternal
	inx
; End of function CombineWordDigits


; =============== S U B R O U T I N E =======================================


CombineWordDigitsInternal:
	lda	0,y
	and	#$F
	sta	0,y
	lda	1,y
	jsr	ShiftLeft4
	ora	0,y
	sta	0,x
	iny
	iny
	rts
; End of function CombineWordDigitsInternal


; =============== S U B R O U T I N E =======================================

; In:

; $0-$3: Split BCD digits
; $4-$7: Split BCD digits
; Out:

; Result of ($0-$3) + ($4-$7) in $0-$3

BCDAdd:
	ldy	#4
	ldx	#0
	clc

loc_BF48:
	lda	0,x
	adc	4,x
	cmp	#$A
	bcc	loc_BF53
	sbc	#$A
	sec

loc_BF53:
	sta	0,x
	inx
	dey
	bne	loc_BF48
	bcc	locret_BF64
	lda	#9	; if there's an overflow, set result to 9999
	ldx	#3

loc_BF5F:
	sta	0,x
	dex
	bpl	loc_BF5F

locret_BF64:
	rts
; End of function BCDAdd


; =============== S U B R O U T I N E =======================================

; In:

; $0-$3: Split BCD digits
; $4-$7: Split BCD digits
; Out:

; Result of ($0-$3) - ($4-$7) in $0-$3

BCDSubtract:
	ldy	#4
	ldx	#0
	sec

loc_BF6A:
	lda	0,x
	sbc	4,x
	bcs	loc_BF73
	adc	#$A
	clc

loc_BF73:
	sta	0,x
	inx
	dey
	bne	loc_BF6A
	bcs	locret_BF84
	lda	#0	; if there's an underflow, set result to 0
	ldx	#3

loc_BF7F:
	sta	0,x
	dex
	bpl	loc_BF7F

locret_BF84:
	rts
; End of function BCDSubtract


; =============== S U B R O U T I N E =======================================


GetDoorPlayerPos:
	lda	#0
	sta	currObjectOffset
	jsr	CopyObjectToZeroPage	; load player object to zero page
	lda	objXPosHi
	and	#$FC
	sta	$0			; x position aligned with chunk boundary
	lda	objYPosHi
	and	#$FC
	sta	$1			; y position aligned with chunk boundary
	ldx	#0

loc_BF9A:
	lda	doorRoomNumTbl,x
	cmp	roomNum			; is the room number equal?
	bne	loc_BFB3
	lda	doorXPosTbl,x
	and	#$FC
	cmp	$0			; is the chunk aligned x pos equal?
	bne	loc_BFB3
	lda	doorYPosTbl,x
	and	#$FC
	cmp	$1			; is the chunk aligned y pos equal?
	beq	loc_BFD5		; we've found a match

loc_BFB3:
	inx
	bne	loc_BF9A

loc_BFB6:
	lda	doorRoomNumTbl2,x
	cmp	roomNum			; is the room number equal?
	bne	loc_BFCF
	lda	doorXPosTbl2,x
	and	#$FC
	cmp	$0			; is the chunk aligned x pos equal?
	bne	loc_BFCF
	lda	doorYPosTbl2,x
	and	#$FC
	cmp	$1			; is the chunk aligned y pos equal?
	beq	loc_BFF5		; we've found a match

loc_BFCF:
	inx
	bne	loc_BFB6
	jmp	CopyZeroPageToObject	; if there's not a match, give up
; ---------------------------------------------------------------------------

loc_BFD5:
	cpx	#0			; is this the door from the last level?
	beq	loc_C011		; if so, check if lucia can go through it
	txa
	eor	#1			; xor 1 = the cooresponding coordinates for the "other side" of the door
	tax
	lda	#$80
	sta	objXPosLo
	sta	objYPosLo
	lda	doorXPosTbl,x
	sta	objXPosHi
	lda	doorYPosTbl,x
	sta	objYPosHi
	lda	doorRoomNumTbl,x
	sta	roomNum
	jmp	CopyZeroPageToObject
; ---------------------------------------------------------------------------

loc_BFF5:
	txa
	eor	#1			; xor 1 = the cooresponding coordinates for the "other side" of the door
	tax
	lda	#$80
	sta	objXPosLo
	sta	objYPosLo
	lda	doorXPosTbl2,x
	sta	objXPosHi
	lda	doorYPosTbl2,x
	sta	objYPosHi
	lda	doorRoomNumTbl2,x
	sta	roomNum
	jmp	CopyZeroPageToObject
; ---------------------------------------------------------------------------

loc_C011:
	lda	orbCollectedFlag	; the last level sets this flag when you kill Darutos
	beq	locret_C019
	lda	#0			; set the flag to display the ending
	sta	objType

locret_C019:
	rts
; End of function GetDoorPlayerPos

; ---------------------------------------------------------------------------
doorXPosTbl:
	db	$36,$00,$25,$7A,$35,$0A,$65,$06
	db	$71,$0E,$55,$4A,$2E,$3E,$32,$06
	db	$55,$6A,$71,$0E,$12,$17,$39,$2A
	db	$5A,$7A,$42,$72,$59,$7A,$69,$7A
	db	$56,$06,$66,$46,$0E,$71,$71,$0E
	db	$49,$17,$39,$17,$59,$17,$15,$36
	db	$69,$3A,$69,$7A,$25,$06,$55,$76
	db	$19,$16,$5A,$5A,$15,$06,$05,$0A
	db	$4A,$1A,$56,$06,$65,$56,$15,$16
	db	$55,$39,$35,$3A,$05,$49,$35,$06
	db	$45,$7A,$65,$5E,$45,$71,$3A,$2A
	db	$4E,$7A,$05,$06,$25,$76,$55,$16
	db	$45,$4A,$35,$09,$45,$0E,$55,$06
	db	$75,$49,$11,$25,$1D,$16,$69,$29
	db	$19,$49,$26,$4D,$15,$46,$45,$49
	db	$5D,$55,$59,$29,$25,$46,$29,$36
	db	$6D,$06,$29,$79,$79,$57,$66,$16
	db	$69,$15,$1D,$36,$0A,$19,$3A,$69
	db	$49,$56,$69,$7A,$2A,$19,$5D,$7A
	db	$69,$6E,$69,$2A,$1D,$6A,$26,$19
	db	$06,$66,$06,$66,$26,$19,$19,$29
	db	$06,$6D,$55,$09,$49,$06,$45,$06
	db	$59,$46,$29,$59,$55,$5A,$3A,$19
	db	$06,$35,$69,$29,$26,$66,$26,$29
	db	$06,$56,$15,$29,$19,$69,$3D,$06
	db	$25,$26,$29,$79,$3D,$5A,$16,$29
	db	$2D,$0E,$55,$1A,$59,$26,$19,$66
	db	$49,$06,$1D,$1D,$36,$36,$56,$56
	db	$59,$36,$69,$16,$19,$59,$39,$7A
	db	$2D,$66,$25,$66,$29,$39,$45,$76
	db	$49,$06,$3A,$06,$46,$16,$3A,$26
	db	$46,$36,$3A,$46,$4E,$56,$2A,$66
doorXPosTbl2:
	db	$3E,$76,$3A,$06,$46,$16,$3A,$26
	db	$46,$36,$2A,$46,$36,$56,$7A,$66
doorYPosTbl:
	db	$0B,$00,$11,$07,$11,$07,$11,$07
	db	$2F,$6F,$31,$17,$67,$13,$67,$47
	db	$71,$07,$0F,$2F,$67,$07,$3C,$61
	db	$3C,$61,$67,$2E,$13,$17,$33,$07
	db	$67,$53,$67,$53,$0F,$6F,$0F,$3F
	db	$2B,$67,$5B,$67,$5B,$67,$11,$53
	db	$13,$07,$43,$27,$71,$17,$71,$53
	db	$23,$33,$23,$3F,$17,$47,$47,$17
	db	$53,$07,$63,$17,$27,$53,$4B,$23
	db	$47,$67,$57,$17,$17,$77,$13,$67
	db	$03,$57,$07,$4F,$07,$4F,$13,$07
	db	$17,$17,$1F,$07,$33,$27,$23,$53
	db	$63,$07,$73,$67,$73,$33,$73,$27
	db	$5F,$67,$07,$27,$0C,$47,$0C,$57
	db	$47,$2C,$57,$3C,$37,$77,$47,$77
	db	$7C,$6B,$23,$77,$37,$27,$37,$23
	db	$43,$77,$73,$77,$0F,$6B,$2B,$67
	db	$7C,$7B,$03,$27,$23,$77,$27,$77
	db	$63,$27,$63,$67,$37,$67,$33,$47
	db	$57,$13,$63,$17,$73,$17,$6B,$5F
	db	$5F,$57,$6F,$67,$47,$4F,$2F,$3C
	db	$3F,$3C,$27,$77,$27,$23,$27,$67
	db	$27,$67,$53,$77,$5F,$17,$17,$4C
	db	$07,$17,$0C,$2C,$37,$37,$67,$7C
	db	$57,$77,$37,$67,$37,$67,$33,$57
	db	$57,$27,$57,$67,$73,$07,$0B,$1C
	db	$03,$23,$07,$17,$07,$53,$23,$53
	db	$23,$57,$4C,$6C,$57,$77,$57,$77
	db	$47,$57,$43,$27,$53,$67,$67,$37
	db	$53,$23,$77,$27,$77,$77,$77,$43
	db	$77,$77,$07,$37,$07,$37,$17,$37
	db	$17,$37,$27,$37,$23,$37,$37,$37
doorYPosTbl2:
	db	$33,$37,$47,$43,$47,$43,$57,$43
	db	$57,$43,$67,$43,$67,$43,$77,$43
doorRoomNumTbl:
	db	$0E,$FF,$00,$0F,$00,$0F,$00,$06
	db	$00,$00,$00,$0F,$00,$07,$00,$06
	db	$00,$0F,$01,$01,$01,$01,$01,$01
	db	$01,$01,$01,$01,$01,$0F,$01,$06
	db	$01,$0F,$01,$0F,$02,$02,$02,$02
	db	$02,$02,$02,$02,$02,$02,$02,$0F
	db	$02,$0F,$02,$06,$02,$07,$02,$0F
	db	$03,$03,$03,$03,$03,$07,$03,$0F
	db	$03,$0F,$03,$06,$03,$0F,$04,$04
	db	$04,$0F,$04,$0F,$04,$0F,$04,$07
	db	$04,$06,$05,$00,$05,$00,$05,$0F
	db	$05,$06,$05,$07,$05,$0F,$05,$0F
	db	$05,$0F,$05,$0F,$05,$06,$05,$0F
	db	$05,$0F,$08,$08,$08,$08,$08,$08
	db	$08,$08,$08,$08,$08,$08,$08,$08
	db	$08,$08,$08,$0F,$08,$0F,$08,$07
	db	$08,$06,$08,$0F,$09,$09,$09,$09
	db	$09,$09,$09,$0F,$09,$0F,$09,$0F
	db	$09,$0F,$09,$06,$0A,$0F,$0A,$06
	db	$0A,$07,$0A,$0F,$0A,$0F,$0B,$0B
	db	$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
	db	$0B,$0B,$0B,$0F,$0B,$07,$0B,$06
	db	$0B,$07,$0B,$0F,$0B,$0F,$0C,$0C
	db	$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
	db	$0C,$0C,$0C,$0F,$0C,$0F,$0C,$06
	db	$0C,$0F,$0C,$0F,$0C,$0F,$0D,$0D
	db	$0D,$06,$0D,$0F,$0D,$0F,$0D,$0F
	db	$0D,$07,$0D,$0D,$0D,$0D,$0D,$0D
	db	$0D,$07,$0D,$0F,$0D,$0F,$0D,$06
	db	$0E,$07,$0E,$0F,$0E,$0F,$0E,$0F
	db	$0E,$07,$06,$0F,$06,$0F,$06,$0F
	db	$06,$0F,$06,$0F,$06,$0F,$06,$0F
doorRoomNumTbl2:
	db	$06,$0F,$06,$0F,$06,$0F,$06,$0F
	db	$06,$0F,$06,$0F,$06,$0F,$06,$0F

; =============== S U B R O U T I N E =======================================


InitRoomVars:
	jsr	LoadRoomPalettes
	jsr	SetRoomCHRBanks
	jsr	InitTilesetPalettePtr
	jsr	ClearLuciaProjectiles
	lda	objXPosHi
	and	#$70
	sta	cameraXHi
	lda	objYPosHi
	and	#$70
	clc
	adc	#1
	sta	cameraYHi
	lda	#0
	sta	bossActiveFlag
	sta	cameraXLo
	sta	cameraYLo
	sta	nametablePosX
	sta	nametablePosY
	sta	luciaHurtPoints
	sta	roomChangeTimer
	sta	currObjectOffset
	sta	attackTimer
	sta	objDirection
	sta	flashTimer
	ldx	#$B

loc_C37F:
	sta	objectTable,x	; Clear Lucia's object slot
	inx
	bne	loc_C37F
	jsr	GetEnemySpawnInfo
	tax	; save enemy spawn info val
	and	#$F0
	cmp	#$A0
	beq	spawnItemPickup
	txa	; restore enemy spawn info val
	cmp	#$B0	; A0-B0: item pickup
	bne	spawnBoss

spawnItemPickup:
	jsr	CheckItemCollectedFlag
	bne	spawnBoss
	lda	#OBJ_ITEM_PICKUP	; "Item pickup" object
	sta	objectTable+$63		; object slot #9
	jsr	GetEnemySpawnInfo
	sec
	sbc	#$A0
	sta	objectTable+$6C		; set the item type from the spawn data
	lda	objYPosHi
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	tax
	lda	objXPosHi
	and	#$70
	ora	#7
	sta	objectTable+$6A		; xPosHi
	lda	objYPosHi
	and	#$70
	ora	itemPickupSpawnYOffsets,x
	sta	objectTable+$68		; yPosHi
	lda	#$80
	sta	objectTable+$6B		; xPosLo
	sta	objectTable+$69		; yPosLo
	lda	#0
	sta	objectTable+$66		; ySpeed
	beq	loc_C40C

spawnBoss:
	lda	roomNum
	cmp	#6
	bne	loc_C3EE		; branch if this isn't the boss room
	ldx	stageNum
	lda	bossDefeatedFlags,x
	bne	loc_C3EE		; branch if the boss has been defeated
	lda	#1
	sta	bossActiveFlag
	ldx	#1
	ldx	stageNum
	lda	bossObjCounts,x
	sta	numBossObjs
	jmp	loc_C40C
; ---------------------------------------------------------------------------

loc_C3EE:
	jsr	GetEnemySpawnInfo
	and	#$F0
	cmp	#$B0			; BX is used for spawning fountains on non-boss rooms
	bne	loc_C3FD
	jsr	SpawnFountain
	jmp	loc_C40C
; ---------------------------------------------------------------------------

loc_C3FD:
	lda	stageNum
	cmp	#$F			; is this the last stage?
	bne	loc_C40C		; branch if not
	lda	hasWingFlag		; has the player collected the wing of madoola?
	bne	loc_C40C		; branch if not
	lda	#OBJ_WING_OF_MADOOLA	; spawn the wing of madoola object
	sta	objectTable+$F2

loc_C40C:
	lda	ppuctrlCopy		; initialize scroll position
	and	#$FC
	sta	ppuctrlCopy
	jsr	ClearOamBuffer
	jsr	SetCameraXY		; initialize camera position
	jsr	SetCameraTiles
	jsr	SetCameraPixels
	lda	cameraXPixels
	and	#$F
	sta	ppuXScrollCopy
	lda	cameraYPixels
	and	#$F
	sta	ppuYScrollCopy
	jsr	InitScrollVars
	lda	#OBJ_LUCIA_NORMAL	; spawn lucia object
	sta	objType
	jsr	InitObjectCollision
	jmp	CopyZeroPageToObject
; End of function InitRoomVars

; ---------------------------------------------------------------------------
itemPickupSpawnYOffsets:
	db	$09
	db	$0B
	db	$09
	db	$0B
bossObjCounts:
	db	01
	db	01
	db	01
	db	01
	db	01
	db	01
	db	01
	db	01
	db	01
	db	50
	db	05
	db	01
	db	01
	db	30
	db	01

; =============== S U B R O U T I N E =======================================


SpawnFountain:
	jsr	GetEnemySpawnInfo
	and	#7
	tax
	lda	fountainXTbl-1,x
	sta	objectTable+$6A	; xPosHi
	lda	fountainYTbl-1,x
	sta	objectTable+$68	; yPosHi
	lda	#OBJ_FOUNTAIN
	sta	objectTable+$63	; type
	ldx	#3

loc_C463:
	lda	fountainPaletteTbl,x
	sta	paletteBuffer+$18,x
	dex
	bne	loc_C463
	rts
; End of function SpawnFountain

; ---------------------------------------------------------------------------
fountainXTbl:
	db	$39
	db	$29
	db	$59
	db	$79
	db	$29
	db	$59
	db	$79
fountainYTbl:
	db	$0A
	db	$1A
	db	$1A
	db	$1A
	db	$26
	db	$26
fountainPaletteTbl:
	db	$26	; this also gets used in fountainYTbl
	db	$03
	db	$31
	db	$21

; =============== S U B R O U T I N E =======================================


SetRoomCHRBanks:
	lda	roomNum
	and	#$F
	cmp	#6	; is this the boss room?
	bne	loc_C48D
	ldx	stageNum
	lda	bossRoomBankTbl,x
	jmp	loc_C491
; ---------------------------------------------------------------------------

loc_C48D:
	tax
	lda	roomBankTbl,x

loc_C491:
	jsr	WriteMapper
	ldx	roomNum
	cpx	#$F
	beq	loc_C4AA
	cpx	#6
	beq	loc_C4A6
	cpx	#7
	beq	loc_C4A6
	lda	#0
	beq	loc_C4AC

loc_C4A6:
	lda	#1
	bne	loc_C4AC

loc_C4AA:
	lda	#2

loc_C4AC:
	sta	scrollMode
	rts
; End of function SetRoomCHRBanks

; ---------------------------------------------------------------------------
bossRoomBankTbl:
	db	$51
	db	$50
	db	$51
	db	$51
	db	$50
	db	$50
	db	$50
	db	$52
	db	$51
	db	$50
	db	$52
	db	$52
	db	$52
	db	$52
	db	$52
	db	$53
roomBankTbl:
	db	$40
	db	$41
	db	$41
	db	$50
	db	$51
	db	$50
	db	$50
	db	$51
	db	$61
	db	$60
	db	$60
	db	$61
	db	$61
	db	$60
	db	$61
	db	$62

; =============== S U B R O U T I N E =======================================


InitTilesetPalettePtr:
	lda	mapperValue
	lsr	a
	lsr	a
	lsr	a
	and	#6	; get lower 2 bits of the CHR bank number
	tax
	lda	tilesetTable,x
	sta	tilesetPalettePtr
	lda	tilesetTable+1,x
	sta	tilesetPalettePtr+1
	rts
; End of function InitTilesetPalettePtr

; ---------------------------------------------------------------------------
tilesetTable:
	dw	outsideTilesetPalettes
	dw	caveTilesetPalettes
	dw	castleTilesetPalettes

; =============== S U B R O U T I N E =======================================

; Returns the current object's screen coordinates.
; Out: X: Object X screen
;      Y: Object Y screen

GetObjScreenCoords:
	lda	objXPosHi
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	and	#7
	tax
	lda	objYPosHi
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	and	#7
	tay
	rts
; End of function GetObjScreenCoords


; =============== S U B R O U T I N E =======================================


CheckItemCollectedFlag:
	jsr	GetObjScreenCoords
	lda	itemCollectedFlags,y
	and	itemCollectedBits,x
	rts
; End of function CheckItemCollectedFlag

; ---------------------------------------------------------------------------
itemCollectedBits:
	db	$01
	db	$02
	db	$04
	db	$08
	db	$10
	db	$20
	db	$40
	db	$80

; =============== S U B R O U T I N E =======================================


SetItemCollectedFlag:
	jsr	GetObjScreenCoords
	lda	itemCollectedFlags,y
	ora	itemCollectedBits,x
	sta	itemCollectedFlags,y
	rts
; End of function SetItemCollectedFlag


; =============== S U B R O U T I N E =======================================


ClearLuciaProjectiles:
	lda	#0
	ldx	#$E

loc_C51E:
	sta	luciaProjectileCoords+1,x
	dex
	dex
	bpl	loc_C51E
	rts
; End of function ClearLuciaProjectiles
