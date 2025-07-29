startGameCode:
	jsr	CopyTitleScreenMusicToRAM
	jsr	TitleScreenLoop
	lda	joy2
	nop	; in the sample version of the game, this said "bmi startMaxxedOutGame"
	nop	; but it got patched out of the retail version
	lda	joy1
	and	#JOY_SELECT	; was select pressed?
	beq	startNewGame	; no? start new game
	lda	gamePlayedFlag
	cmp	#1
	bne	startNewGame
	lda	cheatFlag	; cheatFlag always gets set to 2 when gamePlayedFlag gets
	cmp	#2		; set to 1, so this code doesn't do anything AFAIK
	bne	startMaxxedOutGame
	lda	#0
	sta	healthLo
	lda	#$10
	sta	healthHi
	jmp	getStageReady
; ---------------------------------------------------------------------------

startMaxxedOutGame:
	lda	#$90
	sta	healthLo
	lda	#$99
	sta	healthHi
	lda	#$90
	sta	maxHealthLo
	lda	#$99
	sta	maxHealthHi
	lda	#$90
	sta	maxMagicLo
	lda	#$99
	sta	maxMagicHi
	lda	#$F
	sta	highestReachedStageNum
	lda	#3
	bne	loc_A9E1

startNewGame:
	lda	#0
	sta	healthLo
	lda	#$10
	sta	healthHi
	lda	#0
	sta	maxHealthLo
	lda	#$10
	sta	maxHealthHi
	lda	#0
	sta	maxMagicLo
	lda	#$10
	sta	maxMagicHi
	lda	#0
	sta	highestReachedStageNum
	lda	#0

loc_A9E1:
	ldx	#7

loc_A9E3:
	sta	weaponLevels,x
	dex
	bpl	loc_A9E3
	inc	weaponLevels	; start the regular sword at level 1
	lda	#1
	sta	gamePlayedFlag
	lda	#2
	sta	cheatFlag
	lda	#0
	ldx	#7

loc_A9F6:
	sta	itemCollectedFlags,x
	dex
	bpl	loc_A9F6
	ldx	#$F

loc_A9FE:
	sta	bossDefeatedFlags,x
	dex
	bpl	loc_A9FE
	lda	#0
	sta	hasWingFlag
	sta	usingWingFlag
	sta	orbCollectedFlag
	sta	keywordDisplayFlag

getStageReady:
	jsr	ClearOamBuffer
	jsr	DisableBGAndSprites
	jsr	DisableNMI
	lda	#$38
	sta	ppuctrlCopy
	sta	$2000
	lda	#0
	sta	stageNum
	sta	pausedFlag
	sta	currentWeapon
	lda	highestReachedStageNum
	beq	startStage	; if the player has previously gotten past stage 1,
	jsr	ShowContinue	; show the continue screen

startStage:
	lda	maxMagicLo
	sta	magicLo
	lda	maxMagicHi
	sta	magicHi
	jsr	InitSoundEngine
	lda	#MUS_START	; "before stage" jingle
	jsr	PlaySound
	jsr	DispStatus
	jsr	DispStageNumber
	lda	#$80
	sta	objXPosLo
	sta	objYPosLo
	lda	#0
	sta	hasWingFlag
	lda	stageNum	; x = stageNum * 3
	and	#$F
	asl	a
	clc
	adc	stageNum
	tax
	lda	stageInitTbl,x
	sta	objXPosHi
	lda	stageInitTbl+1,x
	sta	objYPosHi
	lda	stageInitTbl+2,x
	sta	roomNum

loc_AA65:
	jsr	InitRoomVars
	jsr	PlayRoomSong

mainGameLoop:
	inc	frameCounter
	jsr	HandlePaletteShifting
	jsr	WaitVblank
	jsr	ReadControllers
	jsr	nullsub_1
	jsr	HandlePause	; check if start was pressed, do pause menu stuff, etc
	lda	pausedFlag
	bne	afterGameplayStuff
	jsr	ClearOamBuffer
	jsr	DisplayHealthAndMagic
	jsr	HandleObjects
	jsr	HandleScrolling
	jsr	HandleRoomChange

afterGameplayStuff:
	lda	keywordDisplayFlag
	beq	dontShowKeyword
	bpl	initDisplayKeyword

dontShowKeyword:
	lda	roomChangeTimer
	cmp	#1
	beq	loc_AA9E
	jmp	mainGameLoop
; ---------------------------------------------------------------------------

loc_AA9E:
	lda	objectTable
	cmp	#OBJ_LUCIA_DOORWAY	; check for lucia warp door object
	beq	loc_AAAB
	cmp	#OBJ_LUCIA_DYING	; check for lucia dying object
	beq	loc_AAD7
	bne	loc_AABF		; otherwise, it's a level transition

loc_AAAB:
	jsr	GetDoorPlayerPos
	lda	objType
	bne	loc_AA65
	jsr	CopyTitleScreenMusicToRAM
	jsr	ShowEnding
	lda	#0			; disable continues
	sta	gamePlayedFlag
	jmp	startGameCode		; restart game
; ---------------------------------------------------------------------------

loc_AABF:
	lda	stageNum
	clc
	adc	#1
	and	#$F
	sta	stageNum
	cmp	highestReachedStageNum
	beq	loc_AAD4
	bcc	loc_AAD4
	sta	highestReachedStageNum
	lda	#0
	sta	orbCollectedFlag

loc_AAD4:
	jmp	startStage
; ---------------------------------------------------------------------------

loc_AAD7:
	jsr	ShowGameOver
	jmp	startGameCode
; ---------------------------------------------------------------------------

initDisplayKeyword:
	jsr	InitSoundEngine
	lda	#MUS_CLEAR
	jsr	PlaySound
	jsr	DispKeyword
	lda	#$FF
	sta	keywordDisplayFlag	; mark keyword as shown
	lda	#0
	sta	currObjectOffset
	jsr	CopyObjectToZeroPage
	jmp	loc_AA65
; ---------------------------------------------------------------------------
stageInitTbl:
	db	$06,$0E,$00	; start x pos (high), start y pos (high), room number
	db	$06,$0E,$01
	db	$05,$0A,$03
	db	$05,$0A,$05
	db	$37,$3B,$0D
	db	$06,$6E,$02
	db	$05,$4A,$05
	db	$27,$7B,$0D
	db	$06,$2E,$00
	db	$17,$0B,$0A
	db	$17,$7B,$0C
	db	$05,$7A,$04
	db	$67,$7B,$0B
	db	$27,$0B,$09
	db	$37,$1B,$08
	db	$37,$7B,$0E

; =============== S U B R O U T I N E =======================================


PlayRoomSong:
	jsr	InitSoundEngine
	lda	roomNum
	and	#$F
	tax
	cmp	#$E		; are we in room 15? (stage 16's room)
	bne	loc_AB3E
	lda	orbCollectedFlag
	bne	locret_AB4E	; if darutos has been killed, don't play any music
	lda	hasWingFlag	; if Lucia has the wing of madoola, play the castle theme
	bne	loc_AB3E
	lda	#MUS_BOSS	; otherwise play the boss room theme
	bne	loc_AB4B

loc_AB3E:
	lda	roomSongTable,x
	cmp	#MUS_BOSS	; are we playing boss music?
	bne	loc_AB4B
	ldx	bossActiveFlag
	bne	loc_AB4B	; has the boss been killed?
	lda	#MUS_ITEM	; if so, play boss killed music

loc_AB4B:
	jmp	PlaySound
; ---------------------------------------------------------------------------

locret_AB4E:
	rts
; End of function PlayRoomSong

; ---------------------------------------------------------------------------
roomSongTable:
	db	MUS_OVERWORLD
	db	MUS_OVERWORLD
	db	MUS_OVERWORLD
	db	MUS_CAVE
	db	MUS_CAVE
	db	MUS_CAVE
	db	MUS_BOSS
	db	MUS_ITEM
	db	MUS_CASTLE
	db	MUS_CASTLE
	db	MUS_CASTLE
	db	MUS_CASTLE
	db	MUS_CASTLE
	db	MUS_CASTLE
	db	MUS_CASTLE
	db	MUS_ITEM

; =============== S U B R O U T I N E =======================================

; The game stores its title screen and ending music in CHR ROM, this copies it to $400 in RAM

CopyTitleScreenMusicToRAM:
	jsr	DisableNMI
	jsr	DisableBGAndSprites
	lda	$2002
	lda	#$1B	; copy from $1b70 in PPU memory
	sta	$2006
	lda	#$70
	sta	$2006
	sta	$6000
	lda	$2007
	lda	#$00	; copy to $400 in RAM
	sta	$0
	lda	#$4
	sta	$1
	ldx	#4
	ldy	#0

loc_AB84:
	lda	$2007
	sta	(0),y
	iny
	bne	loc_AB84
	inc	$1
	dex
	bne	loc_AB84
	rts
; End of function CopyTitleScreenMusicToRAM


; =============== S U B R O U T I N E =======================================


HandlePause:
	lda	pausedFlag
	beq	notPaused
	lda	joy1Edge
	and	#$10
	beq	loc_AB9F
	jmp	unpauseGame
; ---------------------------------------------------------------------------

loc_AB9F:
	lda	joy1Edge
	and	#$20
	bne	changeWeapon
	beq	loc_ABCD

notPaused:
	lda	joy1Edge
	and	#$10
	bne	pauseGame
	jmp	locret_AC18
; ---------------------------------------------------------------------------

pauseGame:
	jsr	InitSoundEngine
	lda	#SFX_PAUSE
	jsr	PlaySound
	dec	pausedFlag
	bne	loc_ABCD

changeWeapon:
	lda	#SFX_SELECT
	jsr	PlaySound
	inc	currentWeapon
	ldx	currentWeapon
	cpx	#7
	bcc	loc_ABCD
	ldx	#0
	stx	currentWeapon

loc_ABCD:
	jsr	EraseAllWeaponObjects
	lda	#0
	sta	continueCursor
	jsr	MagicSubtract
	bcc	changeWeapon		; skip past this weapon if we don't have enough magic to use it
	ldx	currentWeapon
	lda	weaponLevels,x
	beq	changeWeapon		; skip past this weapon if we don't have it
	cmp	#4
	bcc	loc_ABE7
	lda	#3			; max weapon level is 3
	sta	weaponLevels,x

loc_ABE7:
	ldx	currentWeapon
	lda	pauseWeaponPalettes,x
	tay
	lda	pauseWeaponTiles,x
	sta	oamBuffer+$11
	lda	#$7C			; weapon display x pos
	sta	oamBuffer+$13
	lda	#$20			; weapon display y pos
	sta	oamBuffer+$10
	sty	oamBuffer+$12
	ldx	#7

loc_AC02:
	lda	pauseWeaponBackdrop,x	; write OAM values for the blue square that's behind the weapon
	sta	oamBuffer+$14,x
	dex
	bpl	loc_AC02
	rts
; ---------------------------------------------------------------------------

unpauseGame:
	jsr	PlayRoomSong
	lda	#SFX_PAUSE
	jsr	PlaySound
	lda	#0
	sta	pausedFlag

locret_AC18:
	rts
; End of function HandlePause

; ---------------------------------------------------------------------------
pauseWeaponTiles:
	db	$60
	db	$60
	db	$66
	db	$62
	db	$64
	db	$68
	db	$6A
pauseWeaponPalettes:
	db	$01
	db	$03
	db	$03
	db	$01
	db	$03
	db	$03
	db	$01
pauseWeaponBackdrop:
	db	$20
	db	$4C
	db	$00
	db	$78
	db	$20
	db	$4C
	db	$40
	db	$80

; =============== S U B R O U T I N E =======================================

; Erases all weapon objects (projectiles, that sort of thing)

EraseAllWeaponObjects:
	ldy	#8	; 8 weapon slots
	ldx	#$B	; start at second object

loc_AC33:
	lda	#0
	sta	objectTable,x
	txa
	clc
	adc	#$B
	tax
	dey
	bne	loc_AC33
	ldx	#$F
	lda	#0

loc_AC44:
	sta	luciaProjectileCoords,x
	dex
	bpl	loc_AC44
	rts
; End of function EraseAllWeaponObjects


; =============== S U B R O U T I N E =======================================


HandlePaletteShifting:
	lda	mapperValue
	and	#$30
	bne	locret_AC62
	lda	frameCounter
	and	#3
	bne	locret_AC62
	ldx	paletteBuffer+$F
	lda	paletteBuffer+$E
	sta	paletteBuffer+$F
	lda	paletteBuffer+$D
	sta	paletteBuffer+$E
	stx	paletteBuffer+$D

locret_AC62:
	rts
; End of function HandlePaletteShifting
