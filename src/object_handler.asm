; =============== S U B R O U T I N E =======================================

; 0 - no directions
; 1 - up
; 2 - up & right
; 3 - right
; 4 - down & right
; 5 - down
; 6 - down & left
; 7 - left
; 8 - up & left

SetDirectionPressed:
	lda	joy1
	and	#$F	; isolate d-pad
	tax
	lda	directionTable,x
	sta	directionPressed
	rts
; End of function SetDirectionPressed

; ---------------------------------------------------------------------------
directionTable:
	db	$00	; no directions
	db	$03	; right
	db	$07	; left
	db	$00	; right & left
	db	$05	; down
	db	$04	; down & right
	db	$06	; down & left
	db	$05	; down, left, & right
	db	$01	; up
	db	$02	; up & right
	db	$08	; up & left
	db	$01	; up, left, & right
	db	$00	; up & down
	db	$03	; up, down, & right
	db	$07	; up, down, & left
	db	$00	; up, down, left, & right

; =============== S U B R O U T I N E =======================================


HandleObjects:
	jsr	UpdateRNG
	jsr	SetDirectionPressed
	jsr	HandleWeapon
	lda	#0
	sta	currObjectOffset
	sta	currObjectIndex

loc_DB11:
	ldx	currObjectOffset
	lda	objectTable,x
	beq	loc_DB21
	jsr	CopyObjectToZeroPage
	jsr	RunObjectCode
	jsr	CopyZeroPageToObject

loc_DB21:
	inc	currObjectIndex
	lda	currObjectOffset	; advance to next object
	clc
	adc	#$B			; object size
	sta	currObjectOffset
	bcc	loc_DB11
	lda	scrollMode
	cmp	#2			; spawn enemies if this isn't an item room
	bne	spawnEnemyCheck
	jmp	locret_DBC7
; ---------------------------------------------------------------------------

spawnEnemyCheck:
	jsr	UpdateRNG
	ror	a			; spawn a new enemy if ((rand >> 4) + frameCount) < $20
	ror	a
	ror	a
	ror	a
	adc	frameCounter
	cmp	#$20
	bcc	loc_DB45
	jmp	locret_DBC7
; ---------------------------------------------------------------------------

loc_DB45:
	lda	hasWingFlag		; if lucia has the wing of madoola,
	beq	loc_DB54
	lda	roomNum			; and she's in the final boss room,
	cmp	#$E
	bne	loc_DB54
	lda	#$63			; force the mapper to the bank with darutos's graphics
	jmp	WriteMapper
; ---------------------------------------------------------------------------

loc_DB54:
	jsr	InitEnemyLocation
	lda	bossActiveFlag
	beq	loc_DB76
	jsr	GetEnemySpawnInfo
	and	#$F
	beq	locret_DBC7
	lda	#1
	ldx	stageNum
	cpx	#9			; stage 9 (10 when 1-indexed) has 50 nomajis as the boss
	bne	loc_DB72		; otherwise limit the max # of randomly spawned boss objects to 1
	lda	numBossObjs
	cmp	#12
	bcc	loc_DB72
	lda	#12

loc_DB72:
	sta	maxEnemies
	bne	loc_DB85

loc_DB76:
	jsr	GetEnemySpawnInfo
	lsr	a			; get max # enemies
	lsr	a
	lsr	a
	lsr	a
	beq	locret_DBC7		; return if it's 0 or >= 10
	cmp	#$A
	bcs	locret_DBC7
	sta	maxEnemies

loc_DB85:
	jsr	GetNextEnemyObjSlot
	bne	locret_DBC7		; sets A to $FF if there's no slots available
	stx	currObjectOffset
	lda	roomNum
	cmp	#6			; are we in the boss room?
	bne	notBossRoom
	lda	bossActiveFlag
	beq	locret_DBC7
	ldx	stageNum
	lda	bossObjTypes,x
	jmp	loc_DBB2
; ---------------------------------------------------------------------------

notBossRoom:
	lda	mapperValue
	and	#3			; get current obj bank
	tax
	lda	enemyTypeBaseVals,x
	sta	objType
	jsr	GetEnemySpawnInfo
	and	#$F			; get enemy type offset
	beq	locret_DBC7
	clc
	adc	objType			; add to the base enemy type for this environment

loc_DBB2:
	sta	objType
	cmp	#OBJ_NYURU_INIT		; are we spawning a nyuru?
	bne	loc_DBBD
	lda	#SFX_NYURU		; play sound when spawning a nyuru object
	jsr	PlaySound

loc_DBBD:
	jsr	MakeEnemyFaceLucia
	lda	#0
	sta	objTimer
	jsr	CopyZeroPageToObject

locret_DBC7:
	rts
; End of function HandleObjects

; ---------------------------------------------------------------------------
enemyTypeBaseVals:
	db	$0E
	db	$18
	db	$22
	db	$27
bossObjTypes:
	db	OBJ_HOPEGG_INIT
	db	OBJ_MANTLE_SKULL_INIT
	db	OBJ_NIGITO_INIT
	db	OBJ_SUNEISA_INIT
	db	OBJ_ZADOFLY_INIT
	db	OBJ_PERASKULL_INIT
	db	OBJ_GAGUZUL_INIT
	db	OBJ_BUNYON_INIT
	db	OBJ_JOYRAIMA_INIT
	db	OBJ_NOMAJI_INIT
	db	OBJ_BUNYON_INIT
	db	OBJ_BIFORCE_INIT
	db	OBJ_BOSPIDO_INIT
	db	OBJ_BUNYON_INIT
	db	OBJ_BIFORCE_INIT
	db	OBJ_DARUTOS_INIT

; =============== S U B R O U T I N E =======================================


InitEnemyLocation:
	lda	cameraXLo
	clc
	adc	#$80
	sta	objXPosLo
	lda	cameraXHi
	adc	#0
	sta	objXPosHi
	lda	#0
	sta	objDirection
	jsr	UpdateRNG
	bmi	loc_DBFD	; branch = spawn on left of screen
	lda	#$80
	sta	objDirection
	lda	objXPosHi
	clc
	adc	#$F		; spawn on right edge of screen
	sta	objXPosHi

loc_DBFD:
	lda	#$80
	sta	objYPosLo
	lda	frameCounter	; randomly pick a y value
	and	#$F
	clc
	adc	cameraYHi
	sta	objYPosHi
	jmp	InitObjectCollision
; End of function InitEnemyLocation


; =============== S U B R O U T I N E =======================================


PutObjOnFloor:
	lda	#$10		; 16 * 16 = 256 pixels
	sta	tmpCount

loc_DC11:
	jsr	GetObjMetatile
	cmp	#$24		; is the metatile i'm in solid?
	bcc	loc_DC1F	; if so, move down a metatile
	jsr	GetMetatileBelow
	cmp	#$24		; is the metatile below me solid?
	bcc	loc_DC2F	; if so, exit

loc_DC1F:
	inc	objYPosHi	; move down a metatile
	jsr	IncObjMetatileY
	dec	tmpCount
	bne	loc_DC11
	pla			; eject out of object init subroutine, clear the object type
	pla
	lda	#0
	sta	objType
	rts
; ---------------------------------------------------------------------------

loc_DC2F:
	lda	#$80
	sta	objXPosLo
	sta	objYPosLo
	rts
; End of function PutObjOnFloor


; =============== S U B R O U T I N E =======================================


nullsub_2:
	rts
; End of function nullsub_2


; =============== S U B R O U T I N E =======================================


MakeEnemyFaceLucia:
	lda	objXPosLo
	cmp	objectTable+8
	lda	objXPosHi
	sbc	objectTable+7
	bcs	loc_DC47
	lda	#0
	beq	loc_DC49

loc_DC47:
	lda	#$80

loc_DC49:
	sta	objDirection
	rts
; End of function MakeEnemyFaceLucia


; =============== S U B R O U T I N E =======================================


CopyObjectToZeroPage:
	ldx	#$A
	ldy	currObjectOffset

loc_DC50:
	lda	objectTable,y
	sta	objDirection,x	; TODO add a new "ObjectZeroPage" or something overarching label
	iny
	dex
	bpl	loc_DC50
	rts
; End of function CopyObjectToZeroPage


; =============== S U B R O U T I N E =======================================


CopyZeroPageToObject:
	ldx	#$A
	ldy	currObjectOffset

loc_DC5E:
	lda	objDirection,x
	sta	objectTable,y
	iny
	dex
	bpl	loc_DC5E

locret_DC67:
	rts
; End of function CopyZeroPageToObject


; =============== S U B R O U T I N E =======================================


GetNextEnemyObjSlot:
	lda	maxEnemies	; multiply maxEnemies by 11 (obj slot size)
	asl	a
	asl	a
	sta	$0
	asl	a
	clc
	adc	!$0
	sec
	sbc	maxEnemies
	clc
	adc	#$63	; first enemy slot is at $63 (obj slot size * 9)
	sta	$0
	lda	#$63	; fall through to GetNextObjSlot
; End of function GetNextEnemyObjSlot


; =============== S U B R O U T I N E =======================================

; In: A: Byte offset to start searching at (should be a multiple of $B)
;    $0: Byte offset to end searching at
; Out: A will be $00 if there's room or $FF if there's no room
;      X will be set to the object slot offset if there's room

GetNextObjSlot:
	tax
	lda	objectTable,x
	beq	locret_DC8D
	txa
	clc
	adc	#$B
	cmp	$0
	bcc	GetNextObjSlot
	lda	#$FF

locret_DC8D:
	rts
; End of function GetNextObjSlot


; =============== S U B R O U T I N E =======================================


RunObjectCode:
	lda	objType
	asl	a
	tax
	lda	objSubroutineTable,x
	sta	$E
	lda	objSubroutineTable+1,x
	sta	$F
	jmp	($E)
; End of function RunObjectCode

; ---------------------------------------------------------------------------
objSubroutineTable:
	dw	locret_DC67
	dw	LuciaNormalObj
	dw	LuciaClimbingObj
	dw	LuciaAirLockedObj
	dw	LuciaAirObj
	dw	MagicBombObj
	dw	ShieldBallObj
	dw	BoundBallObj
	dw	MagicBombFireObj
	dw	FlameSwordFireObj
	dw	ExplosionObj
	dw	SmasherObj
	dw	SwordObj
	dw	FlameSwordFlameObj
	dw	SmasherDamageObj
	dw	NomajiInitObj
	dw	NipataInitObj
	dw	DopipuInitObj
	dw	KikuraInitObj
	dw	PeraSkullInitObj
	dw	FireInitObj
	dw	MantleSkullInitObj
	dw	ZadoflyInitObj
	dw	GaguzulInitObj
	dw	0
	dw	SpajyanInitObj
	dw	NyuruInitObj
	dw	NishigaInitObj
	dw	EyemonInitObj
	dw	YokkoChanInitObj
	dw	HopeggInitObj
	dw	NigitoInitObj
	dw	SuneisaInitObj
	dw	JoyraimaInitObj
	dw	HyperEyemonInitObj
	dw	BiforceInitObj
	dw	BospidoInitObj
	dw	0
	dw	DarutosInitObj
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	NomajiObj
	dw	NipataObj
	dw	DopipuObj
	dw	KikuraObj
	dw	PeraSkullObj
	dw	FireObj
	dw	MantleSkullObj
	dw	ZadoflyObj
	dw	GaguzulObj
	dw	0
	dw	SpajyanObj
	dw	NyuruObj
	dw	NishigaObj
	dw	EyemonObj
	dw	YokkoChanObj
	dw	HopeggObj
	dw	NigitoObj
	dw	SuneisaObj
	dw	JoyraimaObj
	dw	0
	dw	BiforceObj
	dw	BospidoObj
	dw	0
	dw	DarutosObj
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	LuciaLvlEndDoorObj
	dw	LuciaDoorwayObj
	dw	ItemPickupObj
	dw	BunyonInitObj
	dw	BunyonObj
	dw	BunyonSplitObj
	dw	MedBunyonInitObj
	dw	MedBunyonObj
	dw	MedBunyonSplitObj
	dw	SmallBunyonInitObj
	dw	SmallBunyonObj
	dw	FountainObj
	dw	LuciaDyingObj
	dw	WingOfMadoolaObj
	dw	FireballObj
