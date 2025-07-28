; +-------------------------------------------------------------------------+
; |                     The Wing of Madoola disassembly                     |
; |  This file is intended to be viewed with the tab size set to 8          |
; |  characters.                                                            |
; +-------------------------------------------------------------------------+

	incl	"variables.asm"	; variable definitions
	incl	"constants.asm"	; constant definitions

; ===========================================================================

	org	$8000
	
	incl	"metatiles.asm"	; Metatile layout data
	incl	"chunks.asm"	; Chunk layout data
	incl	"screens.asm"	; Screen layout data
	incl	"rooms.asm"	; Room layout data
	incl	"palettes.asm"	; Which palette number goes to each metatitle

; ---------------------------------------------------------------------------

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


; =============== S U B R O U T I N E =======================================


DispKeyword:
	jsr	InitPPU
	lda	#$F	; show "THE KEYWORD IS" and wait 150 frames
	sta	paletteBuffer
	lda	#$25
	sta	paletteBuffer+1
	lda	#$29
	sta	paletteBuffer+2
	lda	#$2C
	sta	paletteBuffer+3
	lda	keywordTextPtr
	sta	tmpPtrLo
	lda	keywordTextPtr+1
	sta	tmpPtrHi
	ldx	#$21
	ldy	#$C9
	jsr	PrintText
	jsr	EnableNMI
	lda	#150
	jsr	WaitNFrames
	jsr	InitPPU	; show the keyword (neko dayo~) for 1 second
	ldx	#$21
	ldy	#$4C
	jsr	PrintText
	ldx	#$21
	ldy	#$6B
	jsr	PrintText
	ldx	#$21
	ldy	#$8C
	jsr	PrintText
	ldx	#$21
	ldy	#$EE
	jsr	PrintText
	jsr	EnableNMI
	lda	#60
	jmp	WaitNFrames
; End of function DispKeyword

; ---------------------------------------------------------------------------
keywordText:
	db	'THE KEYWORD IS',0
	db	$29,$2A,$00
	db	$3A,$3B,$3C,$3D,$00
	db	$2B,$2C,$00
	db	$3E,$3F,$5C,$5D,$5E,$5F,$00
keywordTextPtr:
	dw	keywordText

; =============== S U B R O U T I N E =======================================


ShowEndingAnimation:
	lda	#0
	sta	nametablePosY
	sta	oamWriteDirectionFlag
	sta	objDirection
	lda	#$63	; 'c'
	jsr	WriteMapper
	jsr	EnableNMI
	jsr	WaitVblank
	ldx	#$F

loc_ACEE:
	lda	endingSpritePalette,x
	sta	paletteBuffer+$10,x
	dex
	bpl	loc_ACEE
	lda	#30	; show prince lying on ground
	jsr	EndingPrinceSprite
	lda	#0	; load lucia's sprite offscreen
	jsr	EndingLuciaSprite
	jsr	EndingLuciaRun	; show lucia running over to the prince
	lda	#10
	jsr	WaitNFrames
	lda	#30	; show lucia ducking down
	jsr	EndingLuciaSprite
	lda	#50	; show the prince getting up
	jsr	EndingPrinceSprite
	lda	#20	; show prince standing up
	jsr	EndingPrinceSprite
	lda	#40	; show lucia standing up
	jsr	EndingLuciaSprite
	lda	#40	; do a palette shift
	sta	flashTimer
	lda	#20
	jsr	WaitNFrames
	lda	#0	; lucia & prince transform into cool clothes
	jsr	EndingLuciaSprite
	lda	#80
	jsr	EndingPrinceSuitSprite
	lda	#$80
	sta	objDirection
	lda	#$70
	jsr	WriteMapper
	lda	#0	; lucia & prince face forwards
	jsr	EndingLuciaSprite
	lda	#120
	jmp	EndingPrinceSprite
; End of function ShowEndingAnimation

; ---------------------------------------------------------------------------
endingSpritePalette:
	db	$0F,$12,$16,$36
	db	$0F,$1A,$27,$36
	db	$0F,$25,$16,$36
	db	$0F,$2C,$27,$36

; =============== S U B R O U T I N E =======================================

; animates Lucia running to the prince

EndingLuciaRun:
	lda	#8
	sta	spriteX

loc_AD56:
	jsr	WaitVblank
	lda	#$10
	sta	oamWriteCursor
	lda	spriteX
	lsr	a
	lsr	a
	lsr	a
	and	#3
	tax
	lda	luciaRunTiles,x
	sta	spriteTileNum
	jsr	Write16x16SpriteToOAMWithDir
	lda	spriteTileNum
	clc
	adc	#2
	sta	spriteTileNum
	lda	spriteY
	clc
	adc	#$10
	sta	spriteY
	jsr	Write16x16SpriteToOAMWithDir
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	lda	spriteX
	cmp	#120
	beq	locret_ADB6
	clc
	adc	#1
	sta	spriteX
	jmp	loc_AD56
; End of function EndingLuciaRun

; ---------------------------------------------------------------------------
luciaRunTiles:
	db	$04
	db	$08
	db	$0C
	db	$08

; =============== S U B R O U T I N E =======================================


EndingPrinceSprite:
	sta	nametablePosX
	lda	#0
	beq	loc_ADA1
; End of function EndingPrinceSprite


; =============== S U B R O U T I N E =======================================


EndingLuciaSprite:
	sta	nametablePosX
	lda	#$10

loc_ADA1:
	sta	oamWriteCursor
	jsr	LoadEndingSprite
	jsr	Write16x16SpriteToOAMWithDir

loc_ADA9:
	jsr	LoadEndingSprite
	jsr	Write16x16SpriteToOAMWithDir
	lda	nametablePosX
	beq	locret_ADB6
	jmp	WaitNFrames
; ---------------------------------------------------------------------------

locret_ADB6:
	rts
; End of function EndingLuciaSprite


; =============== S U B R O U T I N E =======================================
; This subroutine is a workaround for the prince's head tiles for the "wearing
; suit and facing towards Lucia" frame being below each other in CHR ROM rather
; than being next to each other. 

EndingPrinceSuitSprite:
	sta	nametablePosX
	lda	#0
	sta	oamWriteCursor
	jsr	LoadEndingSprite
	jsr	WriteSpriteToOAMWithDir
	lda	spriteX
	sec
	sbc	#8
	sta	spriteX
	lda	spriteTileNum
	clc
	adc	#2
	sta	spriteTileNum
	jsr	WriteSpriteToOAMWithDir
	jmp	loc_ADA9
; End of function EndingPrinceSuitSprite


; =============== S U B R O U T I N E =======================================


LoadEndingSprite:
	ldx	nametablePosY	; used here as a read cursor for that array
	lda	endingSpriteTbl,x
	sta	spriteY
	inx
	lda	endingSpriteTbl,x
	sta	spriteTileNum
	inx
	lda	endingSpriteTbl,x
	sta	spriteAttrs
	inx
	lda	endingSpriteTbl,x
	sta	spriteX
	inx
	stx	nametablePosY
	rts
; End of function LoadEndingSprite

; ---------------------------------------------------------------------------
endingSpriteTbl:
	db	$A8,$CB,$01,$98
	db	$A8,$EB,$01,$88
	db	$A8,$00,$40,$08
	db	$98,$00,$40,$08
	db	$A0,$00,$40,$78
	db	$B0,$2C,$40,$78
	db	$A0,$AD,$01,$88
	db	$B0,$8F,$01,$88
	db	$98,$AD,$01,$88
	db	$A8,$AF,$01,$88
	db	$98,$E4,$40,$78
	db	$A8,$E6,$40,$78
	db	$98,$C4,$42,$78
	db	$A8,$E8,$42,$78
	db	$98,$8C,$43,$8C
	db	$A8,$EA,$43,$88
	db	$98,$09,$42,$78
	db	$A8,$0B,$42,$78
	db	$98,$0D,$03,$88
	db	$A8,$0F,$03,$88

; =============== S U B R O U T I N E =======================================


ShowEnding:
	jsr	InitSoundEngine
	jsr	InitPPU
	jsr	EnableNMI
	jsr	ShowEndingAnimation	; lucia runs over to the prince, helps him up, etc
	lda	#MUS_ENDING		; play ending music
	jsr	PlaySound
	lda	#$F			; init palette
	sta	paletteBuffer
	lda	#$39
	sta	paletteBuffer+1
	lda	#$29
	sta	paletteBuffer+2
	lda	#$19
	sta	paletteBuffer+3
	lda	#0
	sta	ppuYScrollCopy
	sta	nametablePosY
	sta	vramWriteCount
	lda	#1
	jsr	PlaySound
	jsr	WaitVblank
	lda	endingTextPtr
	sta	tmpPtrLo
	lda	endingTextPtr+1
	sta	tmpPtrHi

loc_AE7F:
	jsr	EndingPrintMsgLine	; loop for scrolling up the ending message
	jsr	EndingScroll4Lines
	jsr	EndingPrintBlankLine
	jsr	EndingScroll4Lines
	lda	nametablePosY
	clc
	adc	#1
	jsr	HandleNametableWrapping
	sta	nametablePosY
	ldy	#0
	lda	(tmpPtrLo),y
	bne	loc_AE7F		; check for end of the message
	lda	#6			; wait 6 seconds on "the end" text

loc_AE9D:
	pha
	lda	#60
	jsr	WaitNFrames
	pla
	sec
	sbc	#1
	bne	loc_AE9D
	rts
; End of function ShowEnding


; =============== S U B R O U T I N E =======================================


EndingScroll4Lines:
	lda	#4

loc_AEAC:
	pha
	lda	#1			; scroll down 1 px (moves text up)
	jsr	ScrollYRelative
	jsr	MoveEndingSpritesUp
	jsr	WaitVblank
	jsr	WaitVblank
	jsr	WaitVblank
	pla
	sec
	sbc	#1
	bne	loc_AEAC
	rts
; End of function EndingScroll4Lines

; ---------------------------------------------------------------------------
endingText:
	db	'   THE EVIL IS DEFEATED NOW.',0,1
	db	'    THE WING OF MADOOLA WILL',0,1
	db	'     BE BRIGHTING OVER THE',0,1
	db	'        WORLD FOR PEACE.',0,1
	db	$01
	db	$01
	db	'   YOU FINISHED THE ADVENTURE.',0,1
	db	'    THANK YOU FOR PLAYING AND',0,1
	db	'      HELPING LUCIA TO SAVE',0,1
	db	'           HER PRINCE.',0,1
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$20,$20,$20,$20,$20,$20,$20,$20,$20,$5B,$01,$02	; "The End" graphic
	db	$03,$04,$05,$20,$06,$07,$05,$21,$22,$23,$24,$00
	db	$20,$20,$20,$20,$20,$20,$20,$20,$15,$10,$11,$12
	db	$13,$14,$20,$20,$16,$14,$17,$25,$26,$27,$28,$00
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$01
	db	$00
endingTextPtr:
	dw	endingText

; =============== S U B R O U T I N E =======================================

; Moves the OAM slots used by the ending sprites up 1 pixel

MoveEndingSpritesUp:
	ldx	#$24

loc_AFFD:
	lda	oamBuffer,x
	cmp	#$F0
	beq	loc_B00A
	sec
	sbc	#1
	sta	oamBuffer,x

loc_B00A:
	txa
	sec
	sbc	#4
	tax
	bpl	loc_AFFD
	rts
; End of function MoveEndingSpritesUp


; =============== S U B R O U T I N E =======================================


EndingPrintMsgLine:
	ldy	#0
	lda	(tmpPtrLo),y
	iny
	cmp	#1
	beq	loc_B040	; 1 = blank line
	lda	#0
	sta	$0
	lda	nametablePosY
	sta	$1
	jsr	CalcVRAMWriteAddr
	jsr	VramWriteLinear
	ldy	#0

loc_B02B:
	lda	(tmpPtrLo),y
	beq	loc_B036
	sta	vramWriteBuff,x
	iny
	inx
	bne	loc_B02B

loc_B036:
	iny
	sty	nametableStartY
	stx	vramWriteCount
	jsr	VramSetWriteCount
	ldy	nametableStartY

loc_B040:
	tya	; add length of string to read cursor
	clc
	adc	tmpPtrLo
	sta	tmpPtrLo
	bcc	locret_B04A
	inc	tmpPtrHi

locret_B04A:
	rts
; End of function EndingPrintMsgLine


; =============== S U B R O U T I N E =======================================


EndingPrintBlankLine:
	lda	#0
	sta	$0
	lda	nametablePosY
	clc
	adc	#1
	jsr	HandleNametableWrapping
	sta	$1
	jsr	CalcVRAMWriteAddr
	jsr	VramWriteLinear
	ldy	#$20	; ' '
	lda	#$20	; ' '      ; ascii space character

loc_B063:
	sta	vramWriteBuff,x
	inx
	dey
	bne	loc_B063
	stx	vramWriteCount
	jmp	VramSetWriteCount
; End of function EndingPrintBlankLine


; =============== S U B R O U T I N E =======================================

; In:

; X: PPU Address high
; Y: PPU address low
;
; $85/$86: Address of text to print

PrintText:
	jsr	SetPPUAddr	; In:
; X: PPU Address high
; Y: PPU Address low
	ldy	#0

printCopyLoop:
	lda	(tmpPtrLo),y	; read from text pointer
	beq	loc_B07F	; if it's 0, exit the loop
	sta	$2007	; else write to vram
	iny
	jmp	printCopyLoop	; read from text pointer
; ---------------------------------------------------------------------------

loc_B07F:
	iny
	tya
	clc
	adc	tmpPtrLo	; add the length of the string to the start pos
	sta	tmpPtrLo	; and overwrite the pointer with the result
	bcc	locret_B08A
	inc	tmpPtrHi

locret_B08A:
	rts
; End of function PrintText


; =============== S U B R O U T I N E =======================================


DispStatus:
	jsr	DisableNMI
	jsr	DisableBGAndSprites
	jsr	ClearNametable
	jsr	ResetScrollPos
	jsr	ClearOamBuffer
	ldx	#$F

loc_B09C:
	lda	gameSpritePalettes,x
	sta	paletteBuffer+$10,x
	lda	statusBGPalette,x
	sta	paletteBuffer,x
	dex
	bpl	loc_B09C
	lda	#0
	sta	$2000
	lda	statusTextPtr
	sta	tmpPtrLo
	lda	statusTextPtr+1
	sta	tmpPtrHi
	ldx	#$20
	ldy	#$6D
	jsr	PrintText	; print status text
	ldx	#$20
	ldy	#$CB
	jsr	PrintText	; print hits text
	ldx	#$21
	ldy	#9
	jsr	PrintText	; print magics text
	ldx	#$21
	ldy	#$6A
	jsr	PrintText	; print sword text
	ldx	#$21
	ldy	#$A4
	jsr	PrintText	; print flame sword text
	ldx	#$21
	ldy	#$E5
	jsr	PrintText	; print magic bomb text
	ldx	#$22
	ldy	#$25
	jsr	PrintText	; bound ball
	ldx	#$22
	ldy	#$64
	jsr	PrintText	; shield ball
	ldx	#$22
	ldy	#$A8
	jsr	PrintText	; smasher
	ldx	#$22
	ldy	#$EA
	jsr	PrintText	; flash
	ldx	#$23
	ldy	#$2A
	jsr	PrintText	; boots
	lda	#0
	sta	oamWriteCursor
	lda	#7
	sta	tmpCount
	lda	#$C5
	sta	spriteY

loc_B111:
	ldx	tmpCount
	lda	weaponLevels,x
	beq	loc_B14D
	sta	tmpCount2
	lda	#$90
	sta	spriteX
	lda	statusItemPalettes,x
	sta	spriteAttrs
	lda	statusItemTiles,x
	sta	spriteTileNum

loc_B127:
	ldx	oamWriteCursor
	lda	spriteY
	sta	oamBuffer,x
	lda	spriteTileNum
	sta	oamBuffer+1,x
	lda	spriteAttrs
	sta	oamBuffer+2,x
	lda	spriteX
	sta	oamBuffer+3,x
	clc
	adc	#$10
	sta	spriteX
	lda	oamWriteCursor
	clc
	adc	#4
	sta	oamWriteCursor
	dec	tmpCount2
	bne	loc_B127

loc_B14D:
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	dec	tmpCount
	bpl	loc_B111
	ldx	#healthLo
	jsr	WordToString
	ldx	#$20
	ldy	#$D1
	jsr	PrintText
	ldx	#maxHealthLo
	jsr	WordToString
	ldx	#$20
	ldy	#$D6
	jsr	PrintText
	ldx	#magicLo
	jsr	WordToString
	ldx	#$21
	ldy	#$11
	jsr	PrintText
	ldx	#maxMagicLo
	jsr	WordToString
	ldx	#$21
	ldy	#$16
	jsr	PrintText
	lda	#$B0
	sta	ppuctrlCopy
	lda	#$72
	jsr	WriteMapper
	jsr	EnableNMI
	lda	#180
	jmp	WaitNFrames	; IN: A - Number of frames to wait
; End of function DispStatus

; ---------------------------------------------------------------------------
statusText:
	db	'STATUS',0; DATA XREF: ROM:statusTextPtr↓o
	db	'HITS  0000/0000',0
	db	'MAGICS  0000/0000',0
	db	'SWORD',0
	db	'FLAME SWORD',0
	db	'MAGIC BOMB',0
	db	'BOUND BALL',0
	db	'SHIELD BALL',0
	db	'SMASHER',0
	db	'FLASH',0
	db	'BOOTS',0
statusTextPtr:
	dw	statusText
statusItemPalettes:
	db	$01
	db	$03
	db	$03
	db	$01
	db	$03
	db	$03
	db	$01
	db	$00
statusItemTiles:
	db	$60
	db	$60
	db	$66
	db	$62
	db	$64
	db	$68
	db	$6A
	db	$BC
statusBGPalette:
	db	$0B,$2B,$2B,$2B
	db	$0B,$2B,$2B,$2B
	db	$0B,$2B,$2B,$2B
	db	$0B,$2B,$2B,$2B

; =============== S U B R O U T I N E =======================================


InitPPU:
	jsr	ClearOamBuffer
	jsr	DisableBGAndSprites
	jsr	DisableNMI
	lda	#0
	sta	flashTimer
	sta	vramWriteCount
	lda	#$B0
	sta	ppuctrlCopy
	lda	#$73	; 's'
	jsr	WriteMapper
	jsr	ClearNametable
	jmp	ResetScrollPos
; End of function InitPPU


; =============== S U B R O U T I N E =======================================


DispStageNumber:
	jsr	InitPPU
	lda	#$F
	sta	paletteBuffer
	lda	#$2C
	sta	paletteBuffer+1
	lda	$2002	; clear PPUADDR latch
	lda	#$21	; write the address
	sta	$2006
	lda	#$EC
	sta	$2006
	ldx	#0

loc_B264:
	lda	stageText,x
	sta	$2007	; write the "STAGE" text
	inx
	cpx	#6
	bne	loc_B264
	lda	stageNum
	asl	a
	tax
	lda	stageNumText,x	; write the stage number
	sta	$2007
	lda	stageNumText+1,x
	sta	$2007
	jsr	EnableNMI
	lda	#180	; wait 3 seconds
	jmp	WaitNFrames	; IN: A - Number of frames to wait
; End of function DispStageNumber

; ---------------------------------------------------------------------------
stageText:
	db	'STAGE ',0
stageNumText:
	db	' 1'; DATA XREF: ROM:B2AE↓o
	db	' 2'
	db	' 3'
	db	' 4'
	db	' 5'
	db	' 6'
	db	' 7'
	db	' 8'
	db	' 9'
	db	'10'
	db	'11'
	db	'12'
	db	'13'
	db	'14'
	db	'15'
	db	'16'
	dw	stageNumText

; =============== S U B R O U T I N E =======================================


ShowGameOver:
	jsr	InitPPU
	lda	#$F
	sta	paletteBuffer
	lda	#$2C
	sta	paletteBuffer+1
	lda	$2002
	lda	#$21
	sta	$2006
	lda	#$EC
	sta	$2006
	ldx	#0

loc_B2CA:
	lda	gameOverText,x
	sta	$2007
	inx
	cpx	#9
	bne	loc_B2CA
	lda	#$70
	jsr	WriteMapper
	jsr	EnableNMI
	lda	#240	; wait 4 seconds
	jmp	WaitNFrames
; End of function ShowGameOver

; ---------------------------------------------------------------------------
gameOverText:
	db	'GAME OVER'

; =============== S U B R O U T I N E =======================================


ShowContinue:
	jsr	InitSoundEngine
	jsr	InitPPU
	lda	#$F		; BUG: The NMI routine only updates color RAM from the palette buffer when
	sta	paletteBuffer   ; there's no queued VRAM write. Because the loop calls VramWriteLinear
	lda	#$23		; each frame, that means the palette never gets written and this code
	sta	paletteBuffer+1	; is left using the title screen palette instead of the intended purple color.
	lda	continueTextPtr	
	sta	tmpPtrLo
	lda	continueTextPtr+1
	sta	tmpPtrHi
	ldx	#$21
	ldy	#$AC
	jsr	PrintText
	ldx	#$21
	ldy	#$EE
	jsr	PrintText
	ldx	#$22
	ldy	#$2E
	jsr	PrintText
	jsr	EnableNMI
	lda	#0
	sta	continueCursor

continueScreenLoop:
	lda	#$2F
	sta	$2
	lda	#$22
	sta	$3
	jsr	VramWriteLinear
	lda	continueCursor
	asl	a
	tay
	lda	stageNumText,y
	sta	vramWriteBuff,x
	inx
	lda	stageNumText+1,y
	sta	vramWriteBuff,x
	inx
	stx	vramWriteCount
	jsr	VramSetWriteCount
	jsr	WaitVblank
	jsr	ReadControllers
	lda	joy1Edge
	lsr	a
	lsr	a
	lsr	a
	bcs	continueScreenDownPressed
	lsr	a
	bcs	continueScreenUpPressed
	lsr	a
	bcc	continueScreenLoop
	lda	continueCursor
	sta	stageNum
	rts
; ---------------------------------------------------------------------------

continueScreenUpPressed:
	lda	continueCursor
	cmp	highestReachedStageNum
	bcs	continueScreenLoop
	inc	continueCursor
	bne	loc_B36B

continueScreenDownPressed:
	dec	continueCursor
	bpl	loc_B36B
	inc	continueCursor
	beq	continueScreenLoop

loc_B36B:
	lda	#SFX_MENU
	jsr	PlaySound
	jmp	continueScreenLoop
; End of function ShowContinue

; ---------------------------------------------------------------------------
continueText:
	db	'CONTINUE',0
	db	'FROM',0
	db	'-1 -',0
continueTextPtr:
	dw	continueText


; =============== S U B R O U T I N E =======================================

; IN: A - Number of frames to wait

WaitNFrames:
	inc	frameCounter
	pha
	jsr	WaitVblank
	pla
	sec
	sbc	#1
	bne	WaitNFrames
	rts
; End of function WaitNFrames


; =============== S U B R O U T I N E =======================================

; Converts a word to an ASCII numeric string
; In: X- Address to low byte of the word
; Clobbers $00-$08

WordToString:
	jsr	SplitOutWordDigits
	ldx	#3
	ldy	#0

loc_B39C:
	lda	0,x
	clc
	adc	#'0'	; convert from digit to ascii
	sta	4,y
	iny
	dex
	bpl	loc_B39C
	lda	#0
	sta	$8	; null-terminate the string
	lda	#4	; write the string pointer
	sta	tmpPtrLo
	lda	#0
	sta	tmpPtrHi
	rts
; End of function WordToString


; =============== S U B R O U T I N E =======================================


EnableBGAndSprites:
	lda	ppumaskCopy
	ora	#$18
	sta	ppumaskCopy
	sta	$2001
	rts
; End of function EnableBGAndSprites


; =============== S U B R O U T I N E =======================================


DisableBGAndSprites:
	lda	ppumaskCopy
	and	#$E7
	sta	ppumaskCopy
	sta	$2001
	rts
; End of function DisableBGAndSprites


; =============== S U B R O U T I N E =======================================


EnableNMI:
	lda	ppuctrlCopy
	ora	#$80
	sta	ppuctrlCopy
	sta	$2000
	rts
; End of function EnableNMI


; =============== S U B R O U T I N E =======================================


DisableNMI:
	lda	ppuctrlCopy
	and	#$7F
	sta	ppuctrlCopy
	sta	$2000
	rts
; End of function DisableNMI


; =============== S U B R O U T I N E =======================================

; In:

; X: PPU Address high
; Y: PPU Address low

SetPPUAddr:
	bit	$2002
	stx	$2006	; write high byte
	sty	$2006	; write low byte
	rts
; End of function SetPPUAddr


; =============== S U B R O U T I N E =======================================


ClearNametable:
	ldx	#$20
	bne	loc_B3ED
	ldx	#$24

loc_B3ED:
	ldy	#0
	jsr	SetPPUAddr
	lda	#$FC	; clear the nametable
	ldy	#$1E

loc_B3F6:
	ldx	#$20

loc_B3F8:
	sta	$2007
	dex
	bne	loc_B3F8
	dey
	bne	loc_B3F6
	ldx	#$40      ; clear the attribute table
	lda	#0

loc_B405:
	sta	$2007
	dex
	bne	loc_B405
	rts
; End of function ClearNametable


; =============== S U B R O U T I N E =======================================


ReadControllers:
	ldx	joyLatchVal	; this seems unnecessary...
	inx
	stx	$4016
	dex
	stx	$4016
	ldx	#8

loc_B418:
	lda	$4016	; read controller 1
	and	#3
	cmp	#1
	rol	joy1Edge	; carry -> bit 0
	lda	$4017	; read controller 2
	and	#3
	cmp	#1
	rol	joy2Edge
	dex
	bne	loc_B418	; read controller 1
	ldx	#1

loc_B42F:
	ldy	joy1Edge,x	; joy values we just read into Y and A
	tya
	eor	joy1,x	; XOR last frame's joy vales
	and	joy1Edge,x	; pressed this frame AND not pressed last frame
	sta	joy1Edge,x
	sty	joy1,x
	dex
	bpl	loc_B42F	; joy values we just read into Y and A
	rts
; End of function ReadControllers


; =============== S U B R O U T I N E =======================================

; X: Low byte of start addr
; Y: High byte of start addr
; A: Number of bytes to clear

ClearMem:
	stx	$E
	sty	$F
	tay
	dey
	lda	#0

loc_B446:
	sta	($E),y
	dey
	bpl	loc_B446
	rts
; End of function ClearMem


; =============== S U B R O U T I N E =======================================


ClearOamBuffer:

; FUNCTION CHUNK AT C64B SIZE 0000000B BYTES

	ldx	#0
	stx	!oamLen
	lda	#$F0

loc_B453:
	sta	oamBuffer,x	; put sprite y offscreen
	inx
	inx
	inx
	inx
	bne	loc_B453	; put sprite y offscreen
	jmp	loc_C64B
; End of function ClearOamBuffer


; =============== S U B R O U T I N E =======================================

; Unused

WaitVBlankEnd:
	lda	$2002
	bpl	WaitVBlankEnd
	rts
; End of function WaitVBlankEnd


; =============== S U B R O U T I N E =======================================


WaitVblank:

; FUNCTION CHUNK AT F3F8 SIZE 00000012 BYTES

	lda	#0
	sta	doneFrame

loc_B469:
	lda	doneFrame
	beq	loc_B469
	jmp	RunSoundEngine
; End of function WaitVblank


; =============== S U B R O U T I N E =======================================

; Unused

ReadMicrophone:

	lda	$4016
	eor	#$FF
	and	#4
	sta	micEdge
	tax
	eor	micData
	and	micEdge
	sta	micEdge
	stx	micData
	rts
; End of function ReadMicrophone


; =============== S U B R O U T I N E =======================================


WriteMapper:
	sta	mapperValue
	rts
; End of function WriteMapper


; =============== S U B R O U T I N E =======================================

; Unused

ResetScrollPosRight:

	lda	ppuctrlCopy
	ora	#1	; set rightmost nametable
	bne	loc_B490
; End of function ResetScrollPosRight


; =============== S U B R O U T I N E =======================================


ResetScrollPos:
	lda	ppuctrlCopy
	and	#$FE	; set leftmost nametable

loc_B490:
	sta	ppuctrlCopy
	lda	#0
	sta	ppuXScrollCopy
	sta	ppuYScrollCopy
	rts
; End of function ResetScrollPos

; ---------------------------------------------------------------------------

ResetVector:
	sei
	cld
	ldx	#$FF	; init stack pointer
	txs
	inx
	stx	vramWriteCount
	stx	flashTimer
	stx	$2000
	stx	$4010	; disable DMC
	lda	#$40
	sta	$4017	; disable APU IRQ

loc_B4AE:
	ldx	$2002
	bpl	loc_B4AE

loc_B4B3:
	ldx	$2002
	bpl	loc_B4B3
	jsr	InitSoundEngine
	ldx	#$E0	; clear $E0 - $FF
	ldy	#0
	lda	#$20
	jsr	ClearMem
	lda	#$28
	sta	ppuctrlCopy
	sta	$2000
	lda	#$1E
	sta	ppumaskCopy
	sta	$2001
	jmp	startGameCode

; =============== S U B R O U T I N E =======================================


SetPaletteBGColors:
	lda	paletteBuffer
	sta	paletteBuffer+4
	sta	paletteBuffer+8
	sta	paletteBuffer+$C
	sta	paletteBuffer+$10
	sta	paletteBuffer+$14
	sta	paletteBuffer+$18
	sta	paletteBuffer+$1C
	rts
; End of function SetPaletteBGColors


; =============== S U B R O U T I N E =======================================


NMIVector:
	php
	pha
	txa
	pha
	tya
	pha
	jsr	DisableBGAndSprites
	lda	doneFrame
	beq	loc_B4F6
	jmp	exitNMIVector
; ---------------------------------------------------------------------------

loc_B4F6:
	dec	doneFrame
	lda	mapperValue	; write to sunsoft-1 mapper
	sta	$6000
	lda	#0	; clear OAMADDR
	sta	$2003
	lda	#2	; DMA $200-$2FF to PPU OAM
	sta	$4014
	lda	vramWriteCount
	bne	doVramWrite
	jsr	SetPaletteBGColors
	lda	$2002
	lda	#$3F	; write to palette
	sta	$2006
	lda	#0
	sta	$2006
	ldx	#0
	ldy	#$1F
	lda	flashTimer
	beq	loc_B537
	dec	flashTimer

loc_B525:
	lda	frameCounter
	asl	a	; mess with the palette to make the screen flash
	asl	a
	and	#$30
	clc
	adc	paletteBuffer,x
	sta	$2007
	inx
	dey
	bpl	loc_B525
	bmi	loc_B540

loc_B537:
	lda	paletteBuffer,x
	sta	$2007
	inx
	dey
	bpl	loc_B537

loc_B540:
	lda	#$3F	; reset ppu address
	sta	$2006
	lda	#0
	sta	$2006
	sta	$2006
	sta	$2006
	beq	loc_B555

doVramWrite:
	jsr	CopyToVRAM

loc_B555:
	lda	ppuctrlCopy
	sta	$2000
	lda	$2002
	lda	ppuXScrollCopy
	sta	$2005
	lda	ppuYScrollCopy
	sta	$2005

exitNMIVector:
	dec	frameTimer
	jsr	EnableBGAndSprites
	pla
	tay
	pla
	tax
	pla
	plp

IRQVector:
	rti
; End of function NMIVector


; =============== S U B R O U T I N E =======================================

; Unused

DebugSpriteViewer:

	jsr	DisableBGAndSprites
	jsr	DisableNMI
	jsr	ClearNametable
	lda	#$A0
	sta	$2000
	lda	#8
	sta	$0
	lda	#$21
	sta	$1
	lda	#0
	sta	$2
	ldy	#$10

loc_B58F:
	lda	$2002
	lda	$1
	sta	$2006
	lda	$0
	sta	$2006
	ldx	#$10
	lda	$2

loc_B5A0:
	sta	$2007
	clc
	adc	#$10
	dex
	bne	loc_B5A0
	clc
	adc	#1
	sta	$2
	lda	$0
	clc
	adc	#$20
	sta	$0
	bcc	loc_B5B9
	inc	$1

loc_B5B9:
	dey
	bne	loc_B58F
	lda	#$A0
	sta	ppuctrlCopy
	jsr	EnableBGAndSprites
	jsr	EnableNMI

loc_B5C6:
	jsr	WaitVblank
	jsr	ReadControllers
	jsr	nullsub_1
	lda	joy1Edge
	and	#$20	; pressing select advances to the next CHR bank
	beq	loc_B5DD
	lda	mapperValue
	clc
	adc	#1
	jsr	WriteMapper

loc_B5DD:
	lda	joy1
	and	#$10	; pressing start quits the viewer
	beq	loc_B5C6
	rts
; End of function DebugSpriteViewer


; =============== S U B R O U T I N E =======================================


LoadRoomPalettes:
	lda	roomNum
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	#$F
	tay
	ldx	#$F

loc_B5F0:
	lda	roomBGPalettes,y
	sta	paletteBuffer,x
	lda	gameSpritePalettes,x
	sta	paletteBuffer+$10,x
	dey
	dex
	bpl	loc_B5F0
	rts
; End of function LoadRoomPalettes

; ---------------------------------------------------------------------------
roomBGPalettes:
	db	$26,$37,$16,$07
	db	$26,$17,$0A,$07
	db	$26,$39,$27,$07
	db	$26,$30,$31,$21
	db	$21,$37,$17,$07
	db	$21,$2A,$0A,$07
	db	$21,$3B,$30,$00
	db	$21,$30,$31,$21
	db	$21,$37,$17,$07
	db	$21,$2A,$0A,$07
	db	$21,$3B,$30,$00
	db	$21,$30,$31,$21
	db	$0F,$37,$17,$07
	db	$0F,$2A,$0A,$07
	db	$0F,$3B,$17,$0C
	db	$0F,$30,$13,$1C
	db	$0F,$10,$00,$0A
	db	$0F,$2A,$1A,$0A
	db	$0F,$3B,$30,$00
	db	$0F,$24,$13,$0C
	db	$0F,$07,$10,$0C
	db	$0F,$15,$26,$02
	db	$0F,$3C,$01,$11
	db	$0F,$25,$15,$04
	db	$0F,$26,$17,$08
	db	$0F,$09,$06,$2F
	db	$0F,$06,$08,$3F
	db	$0F,$02,$2A,$18
	db	$0F,$2B,$1C,$08
	db	$0F,$27,$16,$08
	db	$0F,$30,$10,$00
	db	$0F,$29,$1A,$09
	db	$0F,$3A,$27,$0C
	db	$0F,$1A,$0A,$07
	db	$0F,$3B,$30,$00
	db	$0F,$24,$13,$0C
	db	$0F,$23,$13,$08
	db	$0F,$17,$1B,$07
	db	$0F,$10,$00,$02
	db	$0F,$38,$16,$07
	db	$0F,$10,$00,$08
	db	$0F,$1A,$0C,$09
	db	$0F,$1B,$03,$07
	db	$0F,$15,$05,$3F
	db	$0F,$0A,$14,$07
	db	$0F,$2C,$1C,$0C
	db	$0F,$1C,$32,$21
	db	$0F,$3B,$21,$0C
	db	$00,$31,$22,$03
	db	$00,$0F,$0F,$0F
	db	$00,$16,$0F,$0F
	db	$00,$0F,$11,$2F
	db	$0F,$21,$11,$09
	db	$0F,$10,$00,$2F
	db	$0F,$10,$00,$01
	db	$0F,$24,$13,$0C
	db	$0F,$37,$00,$0F
	db	$0F,$13,$0B,$08
	db	$0F,$1B,$32,$00
	db	$0F,$20,$10,$00
	db	$0F,$05,$16,$08
	db	$0F,$2F,$2F,$18
	db	$0F,$3B,$00,$22
	db	$0F,$21,$1B,$17
gameSpritePalettes:
	db	$00,$12,$16,$36
	db	$00,$1A,$14,$30
	db	$00,$01,$11,$26
	db	$00,$00,$27,$37
	db	$FF

; =============== S U B R O U T I N E =======================================


TitleScreenLoop:
	lda	#0
	sta	flashTimer
	lda	#$30
	sta	ppuctrlCopy
	lda	#$70
	jsr	WriteMapper
	jsr	DisableBGAndSprites
	jsr	DisableNMI
	jsr	ClearNametable
	jsr	ResetScrollPos
	jsr	ClearOamBuffer
	jsr	InitSoundEngine
	lda	#MUS_TITLE
	jsr	PlaySound
	ldx	#$1F

loc_B736:
	lda	titlePalette,x
	sta	paletteBuffer,x
	dex
	bpl	loc_B736
	jsr	DrawTitleScreen
	jsr	EnableNMI

loc_B744:
	jsr	nullsub_1
	jsr	WaitVblank
	jsr	ReadControllers
	lda	joy1Edge
	and	#$10	; was start pressed?
	beq	loc_B744
	rts
; End of function TitleScreenLoop


; =============== S U B R O U T I N E =======================================


DrawTitleScreen:
	ldx	#0
	lda	$2002
	lda	#$20
	sta	$2006
	lda	#$C6
	sta	$2006

loc_B763:
	lda	theWingOfText,x
	beq	loc_B76E
	sta	$2007
	inx
	bne	loc_B763

loc_B76E:
	ldx	#0
	lda	$2002
	lda	#$22
	sta	$2006
	lda	#$66
	sta	$2006

loc_B77D:
	lda	copyrightText,x
	beq	loc_B788
	sta	$2007
	inx
	bne	loc_B77D

loc_B788:
	ldx	#0
	lda	$2002
	lda	#$22
	sta	$2006
	lda	#$A6
	sta	$2006

loc_B797:
	lda	companyText,x
	beq	loc_B7A2
	sta	$2007
	inx
	bne	loc_B797

loc_B7A2:
	ldx	#0
	lda	#6
	sta	$0
	lda	#$21
	sta	$1
	lda	#6
	sta	tmpCount

loc_B7B0:
	lda	$2002
	lda	$1
	sta	$2006
	lda	$0
	sta	$2006
	ldy	#$14

loc_B7BF:
	lda	madoolaTiles,x
	sta	$2007
	inx
	dey
	bne	loc_B7BF
	lda	$0
	clc
	adc	#$20
	sta	$0
	dec	tmpCount
	bne	loc_B7B0
	rts
; End of function DrawTitleScreen

; ---------------------------------------------------------------------------
madoolaTiles:
	db	$FC,$FC,$62,$63,$64,$65,$66,$FC,$62,$69,$6A,$6B,$FC,$6D,$6B,$6D,$6B,$60,$66,$FC
	db	$70,$66,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7D,$61,$67,$76,$77
	db	$80,$FC,$82,$83,$84,$85,$86,$87,$88,$FC,$8A,$8B,$8C,$8D,$8E,$8D,$68,$6C,$86,$6E
	db	$90,$91,$92,$93,$94,$95,$96,$97,$98,$FC,$9A,$9B,$9C,$9D,$9E,$9F,$6F,$95,$96,$71
	db	$FC,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF,$7F,$FC,$A9,$81
	db	$FC,$B1,$B2,$B3,$FC,$FC,$FC,$89,$8F,$99,$A0,$FC,$A0,$FC,$89,$B0,$B4,$B5,$B6,$7F
titlePalette:
	db	$0F,$36,$26,$16
	db	$0F,$11,$21,$31
	db	$0F,$12,$22,$32
	db	$0F,$13,$23,$33
	db	$0F,$10,$20,$30
	db	$0F,$11,$21,$31
	db	$0F,$12,$22,$32
	db	$0F,$13,$23,$33
theWingOfText:
	db	'THE WING OF',0
copyrightText:
	db	'@ 1986 SUNSOFT',0
companyText:
	db	'SUN ELECTRONICS CORP.',0

; =============== S U B R O U T I N E =======================================


HandleScrolling:
	lda	cameraYLo	; camera variable is 12.4 fixed point
	asl	a
	lda	cameraYHi
	rol	a	; A = cameraY in tiles
	cmp	cameraYTiles
	beq	loc_B8D9	; equal? move onto cameraX
	bpl	loc_B8BE
	dec	cameraYTiles
	lda	nametablePosY
	lsr	a
	bcs	loc_B8B8
	lda	metatilePos
	sec
	sbc	#$11
	sta	metatilePos

loc_B8B8:
	dec	nametablePosY
	ldx	#0	; scroll up
	beq	loc_B8D0

loc_B8BE:
	inc	cameraYTiles
	lda	nametablePosY
	lsr	a
	bcc	loc_B8CC
	lda	metatilePos
	clc
	adc	#$11
	sta	metatilePos

loc_B8CC:
	inc	nametablePosY
	ldx	#2	; scroll down

loc_B8D0:
	jsr	SetUpScrollVars
	jsr	DrawLevelRow
	jmp	WriteAttrTblRow
; ---------------------------------------------------------------------------

loc_B8D9:
	lda	cameraXLo
	asl	a
	lda	cameraXHi
	rol	a
	cmp	cameraXTiles
	beq	locret_B90A
	bpl	loc_B8F4
	dec	cameraXTiles
	lda	nametablePosX
	lsr	a
	bcs	loc_B8EE
	dec	metatilePos

loc_B8EE:
	dec	nametablePosX
	ldx	#3	; scroll left
	bne	loc_B901

loc_B8F4:
	inc	cameraXTiles
	lda	nametablePosX
	lsr	a
	bcc	loc_B8FD
	inc	metatilePos

loc_B8FD:
	inc	nametablePosX
	ldx	#1	; scroll right

loc_B901:
	jsr	SetUpScrollVars
	jsr	DrawLevelColumn
	jmp	WriteAttrTblCol
; ---------------------------------------------------------------------------

locret_B90A:
	rts
; End of function HandleScrolling


; =============== S U B R O U T I N E =======================================

; In: X - Scroll direction
; 0 = up, 1 = right, 2 = down, 3 = left

SetUpScrollVars:
	stx	scrollDirection
	lda	nametablePosX
	clc
	adc	scrollXTileOffsets,x
	and	#$3F	; '?'
	sta	nametableStartX
	lda	nametablePosY
	jsr	HandleNametableWrapping
	sta	nametablePosY
	clc
	adc	scrollYTileOffsets,x
	jsr	HandleNametableWrapping
	sta	nametableStartY
	lda	metatilePos
	clc
	adc	metatileOffsets,x
	sta	metatileStart
	lda	cameraXTiles
	clc
	adc	scrollXTileOffsets,x
	sta	copyTileXStart
	lda	cameraYTiles
	clc
	adc	scrollYTileOffsets,x
	sta	copyTileYStart	; fall through to SetUpRoomPointers
; End of function SetUpScrollVars


; =============== S U B R O U T I N E =======================================


SetUpRoomPointers:
	lda	copyTileXStart
	sta	$0
	lda	copyTileYStart
	sta	$1
	lda	roomNum
	lsr	a
	and	#7
	sta	roomScreenPtr+1
	lda	roomNum
	asl	a	; top 3 bits of tile number = screen number
	asl	$1	; (32 * 8 = 256)
	rol	a
	asl	$1
	rol	a
	asl	$1
	rol	a
	asl	$0
	rol	a
	asl	$0
	rol	a
	asl	$0
	rol	a
	clc	; Offset is 00000RRR R0YYYXXX
		; where R is room num, Y is Y screen number, X is X screen number
	adc	#low room0Screens
	sta	roomScreenPtr
	lda	#high room0Screens
	adc	roomScreenPtr+1
	sta	roomScreenPtr+1
	
; this loop runs twice, first it calculates the chunk pointer
; and then it calculates the metatile pointer.
; there are 4 chunks in a screen and 4 metatiles in a chunk
; (so chunks are 64x64px and metatiles are 16x16px)
	
	ldy	#0
	ldx	#2	
loc_B972:
	sty	roomMetatilePtr+1,x
	lda	(roomChunkPtr,x)
	asl	$1
	rol	a
	rol	roomMetatilePtr+1,x
	asl	$1
	rol	a
	rol	roomMetatilePtr+1,x
	asl	$0
	rol	a
	rol	roomMetatilePtr+1,x
	asl	$0
	rol	a
	rol	roomMetatilePtr+1,x
	clc	; Offset is 0000NNNN NNNNYYXX
	adc	metatileBasePtr,x
	sta	roomMetatilePtr,x
	lda	roomMetatilePtr+1,x
	adc	metatileBasePtr+1,x
	sta	roomMetatilePtr+1,x
	dex
	dex
	bpl	loc_B972
	jsr	GetBGBankX2
	lda	(roomMetatilePtr),y	; Y is 0 here so this is just a pointer dereference
	asl	$1
	rol	a
	rol	roomTilePtr+1
	asl	$0
	rol	a
	rol	roomTilePtr+1
	clc	; Offset is 000000NN NNNNNNYX
	adc	tilesetPtrs,x
	sta	roomTilePtr
	lda	roomTilePtr+1
	and	#3
	adc	tilesetPtrs+1,x
	sta	roomTilePtr+1
	rts
; End of function SetUpRoomPointers


; =============== S U B R O U T I N E =======================================

; Returns the bank number of the bank used to store
; background tiles, multiplied by 2 in both A and X.
; Used for pointer offsets, etc

GetBGBankX2:
	lda	mapperValue
	lsr	a
	lsr	a
	lsr	a
	and	#6
	tax
	rts
; End of function GetBGBankX2

; ---------------------------------------------------------------------------
tilesetPtrs:
	dw	outsideTileset
	dw	caveTileset
	dw	castleTileset
	dw	0
scrollXTileOffsets:
	db	$00,$20,$00,$00
scrollYTileOffsets:
	db	$00,$00,$1C,$00
metatileOffsets:
	db	$00,$10,$EE,$00
metatileBasePtr:
	dw	metatileBase
	dw	chunkBase

; =============== S U B R O U T I N E =======================================


DrawLevelRow:
	lda	copyTileXStart
	sta	copyTileX
	lda	copyTileYStart
	sta	copyTileY
	lda	nametableStartX
	sta	nametableWriteX
	lda	nametableStartY
	sta	nametableWriteY
	lda	metatileStart
	sta	objMetatile	; unsure why it's reusing this variable from the object code...
	lda	#$21
	sta	$8	; write counter
	ldy	#0
	sty	dbgMetatileNum

setUpRowWrite:
	lda	nametableWriteX	; set up a linear VRAM write
	sta	$0
	lda	nametableWriteY
	sta	$1
	jsr	CalcVRAMWriteAddr
	jsr	VramWriteLinear

loc_BA05:
	ldx	objMetatile
	lda	(roomMetatilePtr),y
	sta	collisionBuff,x
	cmp	#$F0	; this is an unused debug feature, there's no metatiles with a number >= $F0
	bcc	loc_BA1A
	sta	dbgMetatileNum
	lda	copyTileX
	sta	dbgTileX
	lda	copyTileY
	sta	dbgTileY

loc_BA1A:
	ldx	vramWriteCount	; write the tile to the vram buffer
	lda	(roomTilePtr),y
	sta	vramWriteBuff,x
	inx
	stx	vramWriteCount
	dec	$8
	bne	rowCheckTile
	jmp	VramSetWriteCount	; jump out if we're done writing
; ---------------------------------------------------------------------------

rowCheckTile:
	inc	nametableWriteX
	inc	copyTileX
	lda	copyTileX
	lsr	a
	bcc	rowCheckMetatile	; if we're on a metatile boundary, check if we need to increment the metatile
	inc	roomTilePtr	; else increment the tile
	jmp	rowTileChange
; ---------------------------------------------------------------------------

rowCheckMetatile:
	and	#3
	beq	rowCheckChunk	; if we're on a chunk boundary, check if we need to increment the chunk
	inc	roomMetatilePtr	; else increment the metatile
	jmp	rowMetatileChange
; ---------------------------------------------------------------------------

rowCheckChunk:
	lda	copyTileX
	and	#$1F
	beq	rowIncScreen	; branch if we're on a screen boundary
	inc	roomChunkPtr	; else increment the chunk
	ldx	#0
	jmp	rowChunkChange
; ---------------------------------------------------------------------------

rowIncScreen:
	inc	roomScreenPtr
	bne	loc_BA55
	inc	roomScreenPtr+1

loc_BA55:
	lda	copyTileX
	bne	loc_BA64
	lda	roomScreenPtr	; handle level wraparound
	sec
	sbc	#8
	sta	roomScreenPtr
	bcs	loc_BA64
	dec	roomScreenPtr+1

loc_BA64:
	ldx	#2

rowChunkChange:
	lda	roomMetatilePtr,x
	and	#$C
	sta	roomMetatilePtr,x
	sty	roomMetatilePtr+1,x
	lda	(roomChunkPtr,x)
	asl	a
	rol	roomMetatilePtr+1,x
	asl	a
	rol	roomMetatilePtr+1,x
	asl	a
	rol	roomMetatilePtr+1,x
	asl	a
	rol	roomMetatilePtr+1,x
	ora	roomMetatilePtr,x
	clc
	adc	metatileBasePtr,x
	sta	roomMetatilePtr,x
	lda	roomMetatilePtr+1,x
	adc	metatileBasePtr+1,x
	sta	roomMetatilePtr+1,x
	dex
	dex
	bpl	rowChunkChange

rowMetatileChange:
	jsr	GetBGBankX2
	lsr	roomTilePtr
	lsr	roomTilePtr
	lda	(roomMetatilePtr),y
	rol	a
	rol	roomTilePtr+1
	asl	a
	rol	roomTilePtr+1
	clc
	adc	tilesetPtrs,x
	sta	roomTilePtr
	lda	roomTilePtr+1
	and	#3
	adc	tilesetPtrs+1,x
	sta	roomTilePtr+1
	inc	objMetatile

rowTileChange:
	lda	nametableWriteX
	and	#$1F
	beq	loc_BAB8
	jmp	loc_BA05
; ---------------------------------------------------------------------------

loc_BAB8:
	lda	nametableWriteX
	and	#$3F	; '?'
	sta	nametableWriteX
	jsr	VramSetWriteCount
	jmp	setUpRowWrite
; End of function DrawLevelRow


; =============== S U B R O U T I N E =======================================


DrawLevelColumn:
	lda	copyTileXStart
	sta	copyTileX
	lda	copyTileYStart
	sta	copyTileY
	lda	nametableStartX
	sta	nametableWriteX
	lda	nametableStartY
	sta	nametableWriteY
	lda	metatileStart
	sta	objMetatile
	lda	#$1E
	sta	$8			; $8 - write counter in this function
	ldy	#0
	sty	dbgMetatileNum

loc_BAE0:
	lda	nametableWriteX		; set up a "vertical" vram write
	sta	$0
	lda	nametableWriteY
	sta	$1
	jsr	CalcVRAMWriteAddr
	jsr	VramWriteNTCol

loc_BAEE:
	ldx	objMetatile
	lda	(roomMetatilePtr),y
	sta	collisionBuff,x
	cmp	#$F0			; this might be an unused debug feature, there's no metatiles
	bcc	loc_BB03		; with a number >= $F0
	sta	dbgMetatileNum
	lda	copyTileX
	sta	dbgTileX
	lda	copyTileY
	sta	dbgTileY

loc_BB03:
	ldx	vramWriteCount		; write the tile to the vram buffer
	lda	(roomTilePtr),y
	sta	vramWriteBuff,x
	inx
	stx	vramWriteCount
	dec	$8
	bne	colCheckTile
	jmp	VramSetWriteCount	; jump out if we're done writing
; ---------------------------------------------------------------------------

colCheckTile:
	inc	nametableWriteY
	inc	copyTileY
	lda	copyTileY
	lsr	a
	bcc	colCheckMetatile	; if we're on a metatile boundary, check if we need to go to the next metatile
	lda	roomTilePtr		; otherwise, go to the bottom tile in the current metatile (metatiles are 2x2 tiles)
	ora	#2
	sta	roomTilePtr
	jmp	colTileChange
; ---------------------------------------------------------------------------

colCheckMetatile:
	and	#3			; if we're on a chunk boundary, check if we need to go to the next chunk
	beq	colCheckChunk
	lda	roomMetatilePtr		; otherwise, go to the next row in the current chunk (chunks are 4x4 metatiles)
	clc
	adc	#4
	sta	roomMetatilePtr
	jmp	colMetatileChange
; ---------------------------------------------------------------------------

colCheckChunk:
	lda	copyTileY		; if we're on a screen boundary, handle that
	and	#$1F
	beq	colIncScreen
	lda	roomChunkPtr
	clc				; otherwise, go to the next row in the current screen (screens are 4x4 chunks)
	adc	#4
	sta	roomChunkPtr
	ldx	#0
	jmp	colChunkChange
; ---------------------------------------------------------------------------

colIncScreen:
	lda	roomScreenPtr
	clc
	adc	#8
	sta	roomScreenPtr
	bcc	loc_BB51
	inc	roomScreenPtr+1

loc_BB51:
	lda	copyTileY
	bne	loc_BB60
	lda	roomScreenPtr
	sec				; BUG: pretty sure this is supposed to be #64, not #$64. Shouldn't break
	sbc	#$64			; anything because the game doesn't rely on screen wraparound
	sta	roomScreenPtr
	bcs	loc_BB60
	dec	roomScreenPtr+1

loc_BB60:
	ldx	#2

colChunkChange:
	lda	roomMetatilePtr,x
	and	#3
	sta	roomMetatilePtr,x
	sty	roomMetatilePtr+1,x
	lda	(roomChunkPtr,x)
	asl	a
	rol	roomMetatilePtr+1,x
	asl	a
	rol	roomMetatilePtr+1,x
	asl	a
	rol	roomMetatilePtr+1,x
	asl	a
	rol	roomMetatilePtr+1,x
	ora	roomMetatilePtr,x
	clc
	adc	metatileBasePtr,x
	sta	roomMetatilePtr,x
	lda	roomMetatilePtr+1,x
	adc	metatileBasePtr+1,x
	sta	roomMetatilePtr+1,x
	dex
	dex
	bpl	colChunkChange

colMetatileChange:
	jsr	GetBGBankX2
	lsr	roomTilePtr
	ror	$0
	lda	(roomMetatilePtr),y
	asl	a
	rol	roomTilePtr+1
	asl	$0
	rol	a
	rol	roomTilePtr+1
	clc
	adc	tilesetPtrs,x
	sta	roomTilePtr
	lda	roomTilePtr+1
	and	#3
	adc	tilesetPtrs+1,x
	sta	roomTilePtr+1
	lda	objMetatile
	clc
	adc	#$11
	sta	objMetatile

colTileChange:
	lda	nametableWriteY
	cmp	#$1E
	beq	loc_BBBB
	jmp	loc_BAEE
; ---------------------------------------------------------------------------

loc_BBBB:
	sty	nametableWriteY
	jsr	VramSetWriteCount
	jmp	loc_BAE0
; End of function DrawLevelColumn


; =============== S U B R O U T I N E =======================================


WriteAttrTblRow:
	lda	nametableStartX
	sta	nametableWriteX
	lda	nametableStartY
	sta	nametableWriteY
	jsr	MetatileAlignAT
	ldy	#9
	sty	$8

loc_BBD2:
	lda	nametableWriteX
	sta	$0
	lda	nametableWriteY
	sta	$1
	jsr	NtToAtAddress
	jsr	VramWriteLinear

loc_BBE0:
	jsr	GetATValueX
	ldx	vramWriteCount
	sta	vramWriteBuff,x
	inx
	stx	vramWriteCount
	dec	$8
	bne	loc_BBF2
	jmp	VramSetWriteCount
; ---------------------------------------------------------------------------

loc_BBF2:
	inc	objMetatile
	inc	objMetatile
	lda	nametableWriteX
	clc
	adc	#4
	sta	nametableWriteX
	and	#$1C
	bne	loc_BBE0
	jsr	VramSetWriteCount
	lda	nametableWriteX
	and	#$3F	; '?'
	sta	nametableWriteX
	jmp	loc_BBD2
; End of function WriteAttrTblRow


; =============== S U B R O U T I N E =======================================


WriteAttrTblCol:
	lda	nametableStartX
	sta	nametableWriteX
	lda	#0
	sta	nametableWriteY
	lda	nametableStartY
	lsr	a
	sta	$0
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	$0
	sta	$0
	lda	metatileStart
	sec
	sbc	#1
	sec
	sbc	$0
	sta	objMetatile
	lda	nametableWriteX
	and	#2
	beq	loc_BC35
	dec	objMetatile

loc_BC35:
	lda	nametableWriteX
	sta	$0
	lda	nametableWriteY
	sta	$1
	jsr	NtToAtAddress
	jsr	VramWriteATCol

loc_BC43:
	jsr	GetATValueY
	stx	objMetatile
	ldx	vramWriteCount
	sta	vramWriteBuff,x
	inx
	stx	vramWriteCount
	lda	nametableWriteY
	cmp	#$1E
	bcc	loc_BC43
	jmp	VramSetWriteCount
; End of function WriteAttrTblCol


; =============== S U B R O U T I N E =======================================

; Aligns the metatile to the attribute table 32x32 grid

MetatileAlignAT:
	lda	metatileStart
	sta	objMetatile
	lda	nametableStartY
	and	#2
	beq	loc_BC6A
	lda	objMetatile
	sec
	sbc	#$11
	sta	objMetatile

loc_BC6A:
	lda	nametableStartX
	and	#2
	beq	locret_BC72
	dec	objMetatile

locret_BC72:
	rts
; End of function MetatileAlignAT


; =============== S U B R O U T I N E =======================================

; In:

; X - Offset of the metatile to read
;
; Out:

; Shifts the palette number into the low 2 bytes of $0

GetMetatilePalNum:
	ldy	collisionBuff,x
	lda	(tilesetPalettePtr),y
	lsr	a
	ror	$0
	lsr	a
	ror	$0
	rts
; End of function GetMetatilePalNum


; =============== S U B R O U T I N E =======================================

; Gets the attribute table value for when X scrolling. This is
; different from the Y scrolling one because you have to worry
; about wraparound

GetATValueX:
	lda	scrollDirection
	lsr	a
	bcs	loc_BC92
	lda	scrollDirection
	eor	nametableStartY
	and	#2
	beq	loc_BC92
	lda	scrollDirection
	beq	loc_BCAF
	bne	loc_BCC8

loc_BC92:
	ldx	objMetatile
	jsr	GetMetatilePalNum
	inx
	jsr	GetMetatilePalNum
	txa
	clc
	adc	#$10
	tax
	jsr	GetMetatilePalNum
	inx
	jsr	GetMetatilePalNum
	txa
	clc
	adc	#$10
	tax
	lda	$0
	rts
; ---------------------------------------------------------------------------

loc_BCAF:
	ldx	objMetatile
	dex
	jsr	GetMetatilePalNum
	inx
	jsr	GetMetatilePalNum
	txa
	clc
	adc	#$11
	tax
	jsr	GetMetatilePalNum
	inx
	jsr	GetMetatilePalNum
	lda	$0
	rts
; ---------------------------------------------------------------------------

loc_BCC8:
	ldx	objMetatile
	jsr	GetMetatilePalNum
	inx
	jsr	GetMetatilePalNum
	txa
	clc
	adc	#$11
	tax
	jsr	GetMetatilePalNum
	inx
	jsr	GetMetatilePalNum
	lda	$0
	rts
; End of function GetATValueX


; =============== S U B R O U T I N E =======================================


GetATValueYInternal:
	lda	nametableWriteY
	eor	nametableStartY
	and	#$1E
	bne	loc_BCEA
	inc	objMetatile

loc_BCEA:
	ldx	objMetatile
	jsr	GetMetatilePalNum
	inx
	jsr	GetMetatilePalNum
	txa
	clc
	adc	#$10
	tax
	stx	objMetatile
	lda	nametableWriteY
	clc
	adc	#2
	sta	nametableWriteY
	rts
; End of function GetATValueYInternal


; =============== S U B R O U T I N E =======================================


GetATValueY:
	jsr	GetATValueYInternal
	jsr	GetATValueYInternal
	lda	$0
	rts
; End of function GetATValueY


; =============== S U B R O U T I N E =======================================


InitScrollVars:
	lda	#1
	sta	scrollDirection
	jsr	LuciaSetScroll
	jsr	SetCameraTiles
	jsr	DisableNMI
	jsr	DisableBGAndSprites
	lda	cameraXTiles
	and	#1
	sta	nametablePosX
	sta	nametableStartX
	lda	cameraYTiles
	and	#1
	sta	nametablePosY
	sta	nametableStartY
	lda	#0
	sta	metatilePos
	sta	metatileStart
	lda	cameraXTiles
	sta	copyTileXStart
	lda	cameraYTiles
	sta	copyTileYStart
	ldx	#$1E

loc_BD3B:
	txa
	pha
	jsr	SetUpRoomPointers
	jsr	DrawLevelRow
	jsr	WriteAttrTblRow
	jsr	CopyToVRAM
	inc	nametableStartY
	inc	copyTileYStart
	lda	#1
	bit	nametableStartY
	bne	loc_BD5A
	lda	metatileStart
	clc
	adc	#$11
	sta	metatileStart

loc_BD5A:
	pla
	tax
	dex
	bne	loc_BD3B
	jsr	EnableNMI
	jsr	WaitVblank
	jmp	EnableBGAndSprites
; End of function InitScrollVars


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


; =============== S U B R O U T I N E =======================================


DrawObjNoOffset:
	lda	#0
	sta	dispOffsetX
	sta	dispOffsetY
; End of function DrawObjNoOffset


; =============== S U B R O U T I N E =======================================


DrawObj:
	jsr	CalcObjDispPos
	bne	Write16x16SpriteToOAMWithDir
	rts
; End of function DrawObj


; =============== S U B R O U T I N E =======================================


Write16x16SpriteToOAMWithDir:
	jsr	SetSpriteHFlip

Write16x16SpriteToOAM:
	jsr	CheckForFlicker
	bit	oamWriteDirectionFlag
	bmi	loc_C545
	ldx	oamWriteCursor
	cpx	#$FC
	bne	loc_C553
	ldx	#0
	beq	loc_C553

loc_C545:
	lda	oamWriteCursor
	sec
	sbc	#8
	tax
	cpx	#$FC
	bne	loc_C551
	ldx	#$F8

loc_C551:
	stx	oamWriteCursor

loc_C553:
	lda	spriteY
	sta	oamBuffer,x
	sta	oamBuffer+4,x
	lda	spriteTileNum
	sta	oamBuffer+1,x
	clc
	adc	#$10
	sta	oamBuffer+5,x
	lda	spriteAttrs
	sta	oamBuffer+2,x
	sta	oamBuffer+6,x
	asl	a
	bmi	notMirroredSprite
	lda	spriteX
	sta	oamBuffer+7,x
	sec
	sbc	#8
	sta	oamBuffer+3,x
	jmp	loc_C58A
; ---------------------------------------------------------------------------

notMirroredSprite:
	lda	spriteX
	sta	oamBuffer+3,x
	sec
	sbc	#8
	sta	oamBuffer+7,x

loc_C58A:
	bit	oamWriteDirectionFlag
	bmi	loc_C594
	txa
	clc
	adc	#8
	sta	oamWriteCursor

loc_C594:
	lda	#$FF
	rts
; End of function Write16x16SpriteToOAMWithDir


; =============== S U B R O U T I N E =======================================


DrawObj8x16NoOffset:
	lda	#0
	sta	dispOffsetX
	sta	dispOffsetY

DrawObj8x16:
	jsr	CalcObjDispPos
	bne	WriteSpriteToOAMWithDir
	rts
; End of function DrawObj8x16NoOffset


; =============== S U B R O U T I N E =======================================


WriteSpriteToOAMWithDir:
	jsr	SetSpriteHFlip
; End of function WriteSpriteToOAMWithDir


; =============== S U B R O U T I N E =======================================

; Writes sprite data to the OAM mirror
; Parameters:

; spriteX, spriteY, spriteAttrs, spriteTileNum: OAM values to write

WriteSpriteToOAM:
	lda	oamWriteCursor
	bit	oamWriteDirectionFlag	; $00: Start writing at start of OAM
; $80: Start writing at end of OAM
; This gets alternated every frame to allow for flickering
; if there's too many sprites onscreen
	bpl	loc_C5B1
	sec
	sbc	#4
	sta	oamWriteCursor

loc_C5B1:
	tax
	lda	spriteX
	sec
	sbc	#4
	sta	oamBuffer+3,x
	lda	spriteY
	sta	oamBuffer,x
	lda	spriteAttrs
	sta	oamBuffer+2,x
	lda	spriteTileNum
	sta	oamBuffer+1,x
	txa
	bit	oamWriteDirectionFlag
	bmi	loc_C5D3
	clc
	adc	#4
	sta	oamWriteCursor

loc_C5D3:
	lda	#$FF
	rts
; End of function WriteSpriteToOAM


; =============== S U B R O U T I N E =======================================

; Calculates the position that the currently loaded object should be displayed onscreen.
;
; Out:

; spriteX/spriteY: Object display coordinates
; A gets set to $0 if the object is offscreen
;

CalcObjDispPos:
	lda	objXPosLo
	sec
	sbc	cameraXLo
	sta	spriteX
	lda	objXPosHi
	sbc	cameraXHi
	lsr	a
	ror	spriteX
	lsr	a
	ror	spriteX
	lsr	a
	ror	spriteX
	lsr	a
	bne	objDispOffscreen
	ror	spriteX
	lda	spriteX
	clc
	adc	dispOffsetX
	sta	spriteX
	sec
	sbc	#8
	cmp	#$F1
	bcs	objDispOffscreen
	lda	objYPosLo
	sec
	sbc	cameraYLo
	sta	spriteY
	lda	objYPosHi
	sbc	cameraYHi
	lsr	a
	ror	spriteY
	lsr	a
	ror	spriteY
	lsr	a
	ror	spriteY
	lsr	a
	bne	objDispOffscreen
	lda	spriteY
	ror	a
	clc
	adc	dispOffsetY
	sec
	sbc	#9
	sta	spriteY
	cmp	#$D0
	bcc	loc_C626

objDispOffscreen:
	lda	#0
	rts
; ---------------------------------------------------------------------------

loc_C626:
	lda	#$FF
	rts
; End of function CalcObjDispPos


; =============== S U B R O U T I N E =======================================


SetSpriteHFlip:
	lda	spriteAttrs
	and	#$BF	; clear the "horizontal flip" bit
	sta	spriteAttrs
	lda	objDirection	; MSB is set when facing left
	lsr	a	; move it over a bit
	and	#$40	; isolate the "facing" bit
	eor	#$40	; change it so it's set when facing right (all the sprites are stored facing left)
	ora	spriteAttrs	; apply the bit to the OAM attributes
	sta	spriteAttrs
	rts
; End of function SetSpriteHFlip


; =============== S U B R O U T I N E =======================================

; objDirection serves double duty as an object flicker timer.
; If the lower bits are set, this function will abort sprite
; drawing (on for 2 frames, off for 2 frames, etc) to make the
; object flicker.

CheckForFlicker:
	lda	objDirection
	asl	a
	beq	locret_C64A
	lda	frameCounter
	and	#2
	beq	locret_C64A
	pla	; pull the return address off the stack so we return from the parent function
	pla
	lda	#$FF

locret_C64A:
	rts
; End of function CheckForFlicker

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR ClearOamBuffer

loc_C64B:
	lda	oamWriteDirectionFlag
	eor	#$80
	sta	oamWriteDirectionFlag
	lda	#0
	sta	oamWriteCursor
	rts
; END OF FUNCTION CHUNK FOR ClearOamBuffer

; =============== S U B R O U T I N E =======================================


ShiftLeft4:
	asl	a
	asl	a
	asl	a
	asl	a
	rts
; End of function ShiftLeft4


; =============== S U B R O U T I N E =======================================


ShiftRight4:
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	rts
; End of function ShiftRight4


; =============== S U B R O U T I N E =======================================

; Unused

DecVramTileRow:

	lda	$2
	sec
	sbc	#$20
	bcs	loc_C669
	dec	$3

loc_C669:
	lda	$1
	bne	loc_C67E
	lda	$2
	clc
	adc	#$C0
	sta	$2
	lda	$3
	adc	#3
	sta	$3
	lda	#$1E
	sta	$1

loc_C67E:
	dec	$1
	rts
; End of function DecVramTileRow


; =============== S U B R O U T I N E =======================================


IncVramTileRow:
	lda	$2
	clc
	adc	#$20
	sta	$2
	bcc	loc_C68C
	inc	$3

loc_C68C:
	inc	$1
	lda	$1
	cmp	#$1E
	bne	locret_C6A4
	lda	#0
	sta	$1
	lda	$3
	and	#$24
	sta	$3
	lda	$2
	and	#$1F
	sta	$2

locret_C6A4:
	rts
; End of function IncVramTileRow


; =============== S U B R O U T I N E =======================================


IncVramTileCol:
	inc	$0
	jmp	loc_C6AC
; ---------------------------------------------------------------------------
	dec	$0

loc_C6AC:
	lda	$0
	and	#$3F
	sta	$0
; End of function IncVramTileCol


; =============== S U B R O U T I N E =======================================

; In:

; $0: Start tile X
; $1: Start tile Y
;
; Out:

; $2-3: VRAM write address

CalcVRAMWriteAddr:
	lda	$1
	jsr	HandleNametableWrapping
	sta	$1
	sta	$3
	lda	$0
	and	#$3F
	sta	$0
	and	#$20
	beq	loc_C6C9
	ora	$3
	sta	$3

loc_C6C9:
	lda	$0
	sta	$2
	asl	a
	asl	a
	asl	a
	sec
	ror	$3
	ror	a
	lsr	$3
	ror	a
	lsr	$3
	ror	a
	sta	$2
	rts
; End of function CalcVRAMWriteAddr


; =============== S U B R O U T I N E =======================================

; Unused
; Out: $0: PPU X scroll in tiles
;      $1: PPU Y scroll in tiles

GetPPUScrollInTiles:

	lda	ppuYScrollCopy
	lsr	a
	lsr	a
	lsr	a
	sta	$1
	lda	ppuctrlCopy
	lsr	a
	lda	ppuXScrollCopy
	ror	a
	lsr	a
	lsr	a
	sta	$0
	rts
; End of function GetPPUScrollInTiles


; =============== S U B R O U T I N E =======================================


HandleNametableWrapping:
	bpl	loc_C6F7
	clc
	adc	#$1E
	jmp	HandleNametableWrapping
; ---------------------------------------------------------------------------

loc_C6F7:
	cmp	#$1E
	bcc	locret_C701
	sec
	sbc	#$1E
	jmp	loc_C6F7
; ---------------------------------------------------------------------------

locret_C701:
	rts
; End of function HandleNametableWrapping


; =============== S U B R O U T I N E =======================================

; Unused

sub_C702:

	lda	$0
	lsr	a
	and	#1
	sta	$3
	lda	$1
	and	#2
	ora	$3
	sta	$3
	lda	$0
	lsr	a
	lsr	a
	and	#$F
	sta	$2
	lda	$1
	asl	a
	asl	a
	and	#$70
	ora	$2
	sta	$2
	rts
; End of function sub_C702


; =============== S U B R O U T I N E =======================================

; In -
; $0, $1: Nametable address
;
; Out -
; $2, $3: Attribute table address corresponding to the nametable address

NtToAtAddress:
	lda	$0
	lsr	a
	lsr	a
	and	#7
	sta	$2
	lda	$1
	asl	a
	and	#$38
	ora	$2
	ora	#$C0
	sta	$2
	lda	#$23
	sta	$3
	lda	$0
	and	#$20
	beq	locret_C747
	lda	$3
	ora	#4
	sta	$3

locret_C747:
	rts
; End of function NtToAtAddress

; ---------------------------------------------------------------------------
	db	$FC	; assembler garbage?
	db	$F3
	db	$CF
	db	$3F
	db	$03
	db	$0C
	db	$30
	db	$C0

; =============== S U B R O U T I N E =======================================

; Unused
;
; Shifts left 2 * (value in X)

ShiftLeft2X:
	beq	locret_C758
	asl	a
	asl	a
	dex
	jmp	ShiftLeft2X
; ---------------------------------------------------------------------------

locret_C758:
	rts
; End of function ShiftLeft2X


; =============== S U B R O U T I N E =======================================

; Unused
;
; Shifts right 2 * (value in X) times

ShiftRight2X:
	beq	locret_C761
	lsr	a
	lsr	a
	dex
	jmp	ShiftRight2X
; ---------------------------------------------------------------------------

locret_C761:
	rts
; End of function ShiftRight2X


; =============== S U B R O U T I N E =======================================

; Unused
; In:

; $0,$1: position
; $2,$3: max position
; $4: speed
;
; clamps position between 0 and max position

AddSpeedClamped:

	jsr	AddSpeed
	lda	$0
	cmp	$2
	lda	$1
	sbc	$3
	bcc	locret_C782
	lda	$1
	bmi	loc_C77C
	lda	$2
	sta	$0
	lda	$3
	sta	$1
	rts
; ---------------------------------------------------------------------------

loc_C77C:
	lda	#0
	sta	$0
	sta	$1

locret_C782:
	rts
; End of function AddSpeedClamped


; =============== S U B R O U T I N E =======================================

; In: A (signed): Amount to move X scroll by

ScrollXRelative:
	bmi	loc_C78D
	clc
	adc	ppuXScrollCopy
	sta	ppuXScrollCopy
	bcs	loc_C794
	rts
; ---------------------------------------------------------------------------

loc_C78D:
	clc
	adc	ppuXScrollCopy
	sta	ppuXScrollCopy
	bcs	locret_C79A

loc_C794:
	lda	ppuctrlCopy
	eor	#1
	sta	ppuctrlCopy

locret_C79A:
	rts
; End of function ScrollXRelative


; =============== S U B R O U T I N E =======================================

; In: A (signed): Amount to move Y scroll by

ScrollYRelative:
	cmp	#0
	bmi	loc_C7AC
	clc
	adc	ppuYScrollCopy
	cmp	#$F0
	bcc	loc_C7A9
	clc
	adc	#$10

loc_C7A9:
	sta	ppuYScrollCopy
	rts
; ---------------------------------------------------------------------------

loc_C7AC:
	clc
	adc	ppuYScrollCopy
	bcs	loc_C7B3
	sbc	#$F

loc_C7B3:
	sta	ppuYScrollCopy
	rts
; End of function ScrollYRelative


; =============== S U B R O U T I N E =======================================

; Unused
; $0: Low byte
; $1: High byte

ShiftRight4_16bit:

	lsr	!$1
	ror	!$0
	lsr	!$1
	ror	!$0
	lsr	!$1
	ror	!$0
	lsr	!$1
	ror	!$0
	rts
; End of function ShiftRight4_16bit


; =============== S U B R O U T I N E =======================================

; Unused
; $0: Low byte
; $1: High byte

ShiftLeft4_16bit:

	asl	!$0
	rol	!$1
	asl	!$0
	rol	!$1
	asl	!$0
	rol	!$1
	asl	!$0
	rol	!$1
	rts
; End of function ShiftLeft4_16bit


; =============== S U B R O U T I N E =======================================

; Unused

ShiftLeft_16bit:

	lda	$1
	asl	!$0
	rol	a
	sta	$0
	rts
; End of function ShiftLeft_16bit


; =============== S U B R O U T I N E =======================================

; Unused

ShiftRight_16bit:

	lda	$0
	lsr	a
	sta	$1
	lda	#0
	ror	a
	sta	$0
	rts
; End of function ShiftRight_16bit


; =============== S U B R O U T I N E =======================================

; Unused
;
;
; in:

; $0,$1: pos
; $4: speed
;
; out: $0,$1 += $4

AddSpeed:
	lda	$0
	clc
	adc	$4
	sta	$0
	ror	a	; handle overflow
	eor	$4
	bpl	locret_C811
	lda	$4
	bmi	loc_C80F
	inc	$1
	rts
; ---------------------------------------------------------------------------

loc_C80F:
	dec	$1

locret_C811:
	rts
; End of function AddSpeed


; =============== S U B R O U T I N E =======================================

; Unused

ShiftRight3_16Bit:

	lsr	$1
	ror	$0
	lsr	$1
	ror	$0
	lsr	$1
	ror	$0
	rts
; End of function ShiftRight3_16Bit


; =============== S U B R O U T I N E =======================================

; Unused

ShiftLeft3_16Bit:

	asl	$0
	rol	$1
	asl	$0
	rol	$1
	asl	$0
	rol	$1
	rts
; End of function ShiftLeft3_16Bit


; =============== S U B R O U T I N E =======================================


sub_C82C:

	lda	$0
	bmi	loc_C839
	cmp	$1
	bcc	locret_C845
	lda	$1
	sta	$0
	rts
; ---------------------------------------------------------------------------

loc_C839:
	clc
	adc	$1
	bcc	locret_C845
	lda	#0
	sec
	sbc	$1
	sta	$0

locret_C845:
	rts
; End of function sub_C82C


; =============== S U B R O U T I N E =======================================


UpdateRNG:
	inc	rngVal
	lda	rngVal
	asl	a
	asl	a
	clc
	adc	rngVal
	sta	rngVal
	rts
; End of function UpdateRNG


; =============== S U B R O U T I N E =======================================

; Unused
;
; $0,$1 -= $2,$3

Subtract16Bit:
	lda	$0
	sec
	sbc	$2
	sta	$0
	lda	$1
	sbc	$3
	sta	$1
	rts
; End of function Subtract16Bit


; =============== S U B R O U T I N E =======================================

; Unused
;
; Subtract 16-bit, then negate the result if it's negative

Subtract16BitAbs:

	jsr	Subtract16Bit
	lda	$1
	bpl	locret_C874
	lda	#0
	sec
	sbc	$0
	sta	$0
	lda	#0
	sbc	$1
	sta	$1

locret_C874:
	rts
; End of function Subtract16BitAbs


; =============== S U B R O U T I N E =======================================

; Unused, uses outdated variables so you probably shouldn't use it

CalcObjDispPosOld:
	lda	objXPosLo
	sta	spriteX
	lda	objXPosHi
	lsr	a
	ror	spriteX
	lsr	a
	ror	spriteX
	lsr	a
	ror	spriteX
	lsr	a
	ror	spriteX
	and	#7
	sta	spriteY
	lda	objYPosLo
	sta	spriteY
	lda	objYPosHi
	lsr	a
	ror	spriteY
	lsr	a
	ror	spriteY
	lsr	a
	ror	spriteY
	lsr	a
	ror	spriteY
	and	#7
	sta	luciaXPosLo
	rts
; End of function CalcObjDispPosOld


; =============== S U B R O U T I N E =======================================

; Unused, I would recommend using CalcObjDispPos instead

CalcObjDispPosScrollOld:

	jsr	CalcObjDispPosOld
	lda	spriteX
	sec
	sbc	cameraXLo
	sta	$0
	lda	spriteY
	sbc	cameraXHi
	bne	loc_C8C0
	lda	spriteY
	sec
	sbc	cameraYLo
	sta	$2
	lda	luciaXPosLo
	sbc	cameraYHi
	bne	loc_C8C0
	rts
; ---------------------------------------------------------------------------

loc_C8C0:
	lda	#$F4
	sta	$2
	rts
; End of function CalcObjDispPosScrollOld


; =============== S U B R O U T I N E =======================================

; Unused
; Simpler version of UpdateObjXYPos that doesn't test for collision

UpdateObjXYPosOld:

	lda	objXPosLo
	sta	$0
	lda	objXPosHi
	sta	$1
	lda	objXSpeed
	sta	$4
	jsr	AddSpeed
	lda	$0
	sta	objXPosLo
	lda	$1
	sta	objXPosHi
	lda	objYPosLo
	sta	$0
	lda	objYPosHi
	sta	$1
	lda	objYSpeed
	sta	$4
	jsr	AddSpeed
	lda	$0
	sta	objYPosLo
	lda	$1
	sta	objYPosHi
	rts
; End of function UpdateObjXYPosOld


; =============== S U B R O U T I N E =======================================


IncObjMetatileX:
	inc	objMetatile
	rts
; End of function IncObjMetatileX


; =============== S U B R O U T I N E =======================================


IncObjMetatileY:
	lda	objMetatile
	clc
	adc	#$11
	sta	objMetatile
	rts
; End of function IncObjMetatileY


; =============== S U B R O U T I N E =======================================

; Unused

sub_C8FF:

	bpl	loc_C905
	clc
	adc	#$26
	rts
; ---------------------------------------------------------------------------

loc_C905:
	cmp	#$26
	bcc	locret_C90C
	sec
	sbc	#$26

locret_C90C:
	rts
; End of function sub_C8FF


; =============== S U B R O U T I N E =======================================


nullsub_3:

	rts
; End of function nullsub_3


; =============== S U B R O U T I N E =======================================

; Unused
; $0,$1 = $0,$1 + $2,$3

Add16Bit:

	lda	$0
	clc
	adc	$2
	sta	$0
	lda	$1
	adc	$3
	sta	$1
	rts
; End of function Add16Bit


; =============== S U B R O U T I N E =======================================


DecObjMetatileX:
	dec	objMetatile
	rts
; End of function DecObjMetatileX


; =============== S U B R O U T I N E =======================================


DecObjMetatileY:
	lda	objMetatile
	sec
	sbc	#$11
	sta	objMetatile
	rts
; End of function DecObjMetatileY


; =============== S U B R O U T I N E =======================================


GetObjMetatile:
	ldx	objMetatile
	lda	collisionBuff,x
	rts
; End of function GetObjMetatile


; =============== S U B R O U T I N E =======================================


InitObjectCollision:
	lda	cameraXTiles
	lsr	a
	sta	$0
	lda	objXPosHi
	sec
	sbc	$0
	clc
	adc	metatilePos
	sta	objMetatile
	lda	cameraYTiles
	lsr	a
	sta	$0
	lda	objYPosHi
	sec
	sbc	$0
	sta	$0
	asl	a
	asl	a
	asl	a
	asl	a
	clc
	adc	$0
	clc
	adc	objMetatile
	sta	objMetatile
	rts
; End of function InitObjectCollision


; =============== S U B R O U T I N E =======================================

; Unused

CollisionBuffWrite:

	ldx	objMetatile
	sta	collisionBuff,x
	rts
; End of function CollisionBuffWrite


; =============== S U B R O U T I N E =======================================

; Unused

LimitCamera:

	lda	cameraXHi
	and	#7
	sta	cameraXHi
	lda	cameraYHi
	and	#7
	sta	cameraYHi
	rts
; End of function LimitCamera


; =============== S U B R O U T I N E =======================================

; Uses Lucia's position to set the scroll vars

LuciaSetScroll:
	lda	scrollMode
	cmp	#2	; scroll mode 2: no scrolling at all
	beq	locret_C9E6
	jsr	SetCameraX
	lda	scrollMode
	cmp	#1	; scroll mode 1: only x scrolling
	beq	locret_C9E6
	lda	objYPosLo
	sec
	sbc	cameraYLo
	lda	objYPosHi
	sbc	cameraYHi
	cmp	#3	; top scroll threshold
	bcc	loc_C996
	cmp	#$A	; bottom scroll theshold
	bcs	loc_C996
	lda	usingWingFlag	; always scroll when flying
	bne	loc_C996
	lda	objectTable	; type of first object in object table
	sec
	sbc	#OBJ_LUCIA_AIR_LOCKED	; don't scroll vertically if object type is air or air locked
	and	#$FE
	beq	locret_C9E6

loc_C996:
	lda	objYPosLo
	sta	$0
	lda	objYPosHi
	sec
	sbc	#$A
	sta	$1
	jsr	CmpCameraY
	bpl	loc_C9C1
	lda	cameraYLo
	clc
	adc	#$40
	sta	cameraYLo
	bcc	loc_C9B1
	inc	cameraYHi

loc_C9B1:
	jsr	CmpCameraY
	bmi	loc_C9D9
	lda	$0
	sta	cameraYLo
	lda	$1
	sta	cameraYHi
	jmp	loc_C9D9
; ---------------------------------------------------------------------------

loc_C9C1:
	lda	cameraYLo
	sec
	sbc	#$40
	sta	cameraYLo
	bcs	loc_C9CC
	dec	cameraYHi

loc_C9CC:
	jsr	CmpCameraY
	bpl	loc_C9D9
	lda	$0
	sta	cameraYLo
	lda	$1
	sta	cameraYHi

loc_C9D9:
	lda	cameraYHi
	jmp	loc_CA21
; End of function LuciaSetScroll


; =============== S U B R O U T I N E =======================================

; Compares the camera Y value with the value stored in $0/$1

CmpCameraY:
	lda	cameraYLo
	cmp	$0
	lda	cameraYHi
	sbc	$1

locret_C9E6:
	rts
; End of function CmpCameraY


; =============== S U B R O U T I N E =======================================


SetCameraXY:
	jsr	SetCameraY
; End of function SetCameraXY


; =============== S U B R O U T I N E =======================================


SetCameraX:
	lda	scrollMode
	cmp	#2
	beq	locret_CA10
	lda	objXPosLo
	sta	cameraXLo
	lda	objXPosHi
	sec
	sbc	#8
	sta	cameraXHi
	bpl	loc_CA04
	lda	#0	; min camera x threshold
	sta	cameraXLo
	sta	cameraXHi
	rts
; ---------------------------------------------------------------------------

loc_CA04:
	cmp	#$70	; max camera x threshold
	bcc	locret_CA10
	lda	#0
	sta	cameraXLo
	lda	#$70
	sta	cameraXHi

locret_CA10:
	rts
; End of function SetCameraX


; =============== S U B R O U T I N E =======================================


SetCameraY:
	lda	scrollMode
	beq	loc_CA16
	rts
; ---------------------------------------------------------------------------

loc_CA16:
	lda	objYPosLo
	sta	cameraYLo
	lda	objYPosHi
	sec
	sbc	#$A
	sta	cameraYHi

loc_CA21:
	bpl	loc_CA2A
	lda	#0	; min camera y threshold
	sta	cameraYLo
	sta	cameraYHi
	rts
; ---------------------------------------------------------------------------

loc_CA2A:
	cmp	#$71	; max camera y threshold
	bcc	locret_CA36
	lda	#0
	sta	cameraYLo
	lda	#$71
	sta	cameraYHi

locret_CA36:
	rts
; End of function SetCameraY


; =============== S U B R O U T I N E =======================================


SetCameraTiles:
	lda	cameraXLo
	asl	a
	lda	cameraXHi
	rol	a
	sta	cameraXTiles
	lda	cameraYLo
	asl	a
	lda	cameraYHi
	rol	a
	sta	cameraYTiles
	rts
; End of function SetCameraTiles


; =============== S U B R O U T I N E =======================================


SetCameraPixels:
	lda	cameraXLo
	sta	cameraXPixels
	lda	cameraXHi
	lsr	a
	ror	cameraXPixels
	lsr	a
	ror	cameraXPixels
	lsr	a
	ror	cameraXPixels
	lsr	a
	ror	cameraXPixels
	lda	cameraYLo
	sta	cameraYPixels
	lda	cameraYHi
	lsr	a
	ror	cameraYPixels
	lsr	a
	ror	cameraYPixels
	lsr	a
	ror	cameraYPixels
	lsr	a
	ror	cameraYPixels
	rts
; End of function SetCameraPixels


; =============== S U B R O U T I N E =======================================

; Unused

SetObjPosFromScroll:

	lda	copyTileX
	sta	objXPosHi
	lda	#0
	lsr	objXPosHi
	ror	a
	sta	objXPosLo
	lda	copyTileY
	sta	objYPosHi
	lda	#0
	lsr	objYPosHi
	ror	a
	sta	objYPosLo
	rts
; End of function SetObjPosFromScroll


; =============== S U B R O U T I N E =======================================

; Unused

SaveObjMetatile:

	lda	objMetatile
	sta	$F
	rts
; End of function SaveObjMetatile


; =============== S U B R O U T I N E =======================================

; Unused

LoadObjMetatile:

	pha
	lda	$F
	sta	objMetatile
	pla
	rts
; End of function LoadObjMetatile


; =============== S U B R O U T I N E =======================================

; Unused
; Writes A to the VRAM write buffer

VramWriteByte:

	ldx	vramWriteCount
	sta	vramWriteBuff,x
	inx
	stx	vramWriteCount
	rts
; End of function VramWriteByte


; =============== S U B R O U T I N E =======================================

; For writing attribute table columns (increment by 8)
; In: $2 - low byte of VRAM address
;     $3 - high byte of VRAM address

VramWriteATCol:
	lda	#$40
	bne	loc_CAA3
; End of function VramWriteATCol


; =============== S U B R O U T I N E =======================================

; For writing linear data (increment by 1)
; In: $2 - low byte of VRAM address
;     $3 - high byte of VRAM address

VramWriteLinear:
	lda	#0
	beq	loc_CAA3
; End of function VramWriteLinear


; =============== S U B R O U T I N E =======================================

; For writing nametable columns (increment by 32)
; In: $2 - low byte of VRAM address
;     $3 - high byte of VRAM address

VramWriteNTCol:
	lda	#$80

loc_CAA3:
	ldx	vramWriteCount
	sta	vramWriteBuff+2,x
	lda	$2
	sta	vramWriteBuff,x
	inx
	lda	$3
	sta	vramWriteBuff,x
	inx
	stx	vramBuffEnd
	inx
	stx	vramWriteCount
	rts
; End of function VramWriteNTCol


; =============== S U B R O U T I N E =======================================

; Sets the write count for the first VRAM write command
; to the total number of bytes in the VRAM write buffer.

VramSetWriteCount:
	lda	vramWriteCount
	clc
	sbc	vramBuffEnd
	ldx	vramBuffEnd
	ora	vramWriteBuff,x
	sta	vramWriteBuff,x
	rts
; End of function VramSetWriteCount


; =============== S U B R O U T I N E =======================================


CopyToVRAM:
	ldx	#0

checkTilemapCount:
	cpx	vramWriteCount
	bcc	loc_CAD3	; keep writing if x < tilemapWriteCount
	lda	#0
	sta	vramWriteCount
	rts
; ---------------------------------------------------------------------------

loc_CAD3:
	lda	$2002	; clear PPUADDR latch
	lda	vramWriteBuff+1,x	; upper byte of write address
	sta	$2006
	sta	ppuAddrHi
	lda	vramWriteBuff,x	; lower byte of write address
	sta	$2006
	sta	ppuAddrLo
	inx	; skip past the address
	inx
	lda	vramWriteBuff,x
	and	#$40
	bne	incrementBy8	; if bit 6 is set, increment by 8
	lda	vramWriteBuff,x
	bmi	incrementBy32	; if bit 7 is set, increment by 32
	lda	#0	; else, increment by 1 (write row)
	jmp	loc_CAFB
; ---------------------------------------------------------------------------

incrementBy32:
	lda	#4	; increment by 32 (write column)

loc_CAFB:
	sta	$2000
	lda	vramWriteBuff,x
	and	#$3F
	tay	; number of bytes to write
	inx

loc_CB05:
	lda	vramWriteBuff,x
	sta	$2007
	inx
	dey
	bne	loc_CB05
	jmp	checkTilemapCount
; ---------------------------------------------------------------------------

incrementBy8:
	lda	vramWriteBuff,x	; incrementing by 8 is used for updating columns in
; the attribute table
	and	#$3F
	tay	; number of bytes to write
	inx

loc_CB19:
	lda	$2002
	lda	ppuAddrHi
	sta	$2006
	lda	ppuAddrLo
	sta	$2006
	clc
	adc	#8
	sta	ppuAddrLo
	lda	vramWriteBuff,x
	sta	$2007
	inx
	dey
	bne	loc_CB19
	jmp	checkTilemapCount
; End of function CopyToVRAM

; ---------------------------------------------------------------------------
luciaXSpeedTbl:
	db	$00,$00,$18,$18,$18,$00,$E8,$E8,$E8	; speeds are 4.4 fixed point
	db	$00,$00,$1C,$1C,$1C,$00,$E4,$E4,$E4
	db	$00,$00,$20,$20,$20,$00,$E0,$E0,$E0
	db	$00,$00,$28,$28,$28,$00,$D8,$D8,$D8
luciaYSpeedTbl:
	db	$00,$F0,$F0,$00,$10,$10,$10,$00,$F0
	db	$00,$E8,$E8,$00,$18,$18,$18,$00,$E8
	db	$00,$E0,$E0,$00,$20,$20,$20,$00,$E0
	db	$00,$D8,$D8,$00,$28,$28,$28,$00,$D8
luciaJumpSpeedTbl:
	db	$B4,$AE,$A0,$80

; =============== S U B R O U T I N E =======================================


GetLuciaSpeedTblOffset:
	lda	bootsLevel
	asl	a
	asl	a
	asl	a
	clc
	adc	bootsLevel
	clc
	adc	directionPressed
	tax
	rts
; End of function GetLuciaSpeedTblOffset


; =============== S U B R O U T I N E =======================================


LuciaNormalObj:
	jsr	GetLuciaSpeedTblOffset
	lda	luciaXSpeedTbl,x
	sta	objXSpeed
	lda	luciaYSpeedTbl,x
	sta	objYSpeed
	lda	attackTimer
	beq	loc_CBA6	; don't move if you're attacking
	lda	#0
	sta	objXSpeed

loc_CBA6:
	jsr	SetObjDirection
	jsr	UpdateObjXPos
	jsr	CheckSolidBelow	; check ground collision
	bne	loc_CBBE
	lda	#$20	; falling speed
	sta	objYSpeed
	lda	#OBJ_LUCIA_AIR	; change lucia's object to "in air"
	sta	objType
	lda	#5
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CBBE:
	bit	joy1Edge		; check for jump
	bpl	loc_CBF7
	lda	#SFX_JUMP		; play jumping sound
	jsr	PlaySound
	ldx	bootsLevel
	lda	luciaJumpSpeedTbl,x
	sta	objYSpeed
	lda	#OBJ_LUCIA_AIR
	cpx	#2			; if the boots level is at least 2, the player can control Lucia's
	bcs	loc_CBD6		; movement when she's jumping
	lda	#OBJ_LUCIA_AIR_LOCKED	; otherwise, set lucia's object to "in air, locked movement"

loc_CBD6:
	sta	objType
	lda	#0			; clear the "using the wing of madoola" flag
	sta	usingWingFlag
	lda	hasWingFlag		; if the player has the wing, and is pressing down and A, and has enough
	beq	loc_CBF2		; magic, set the "using the wing of madoola" flag
	lda	joy1
	and	#4
	beq	loc_CBF2
	lda	#7
	jsr	MagicSubtractA
	bcc	loc_CBF2
	jsr	CombineWordDigits
	dec	usingWingFlag

loc_CBF2:
	lda	#5
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CBF7:
	lda	objXSpeed
	bne	loc_CC2B
	lda	objMetatile
	ldx	objYSpeed
	beq	loc_CC2B
	bpl	loc_CC09	; if lucia's moving down, check the below metatile
	sec			; otherwise check the above metatile
	sbc	#$11
	jmp	loc_CC0C
; ---------------------------------------------------------------------------

loc_CC09:
	clc
	adc	#$11

loc_CC0C:
	tax
	lda	collisionBuff,x
	cmp	#$1F			; solid ground? set y speed to 0
	bcc	loc_CC27
	cmp	#$24			; scenery? also set y speed to 0
	bcs	loc_CC27
	jsr	MetatileAlignObjX	; otherwise, it's a ladder
	jsr	UpdateObjYPos
	lda	#OBJ_LUCIA_CLIMB	; set lucia's object type to "climbing"
	sta	objType
	lda	#7
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CC27:
	lda	#0
	sta	objYSpeed

loc_CC2B:
	lda	attackTimer		; set up lucia's animation frame
	bne	loc_CC33
	lda	objXSpeed
	bne	loc_CC3E

loc_CC33:
	lda	joy1
	and	#4
	bne	loc_CC48
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CC3E:
	lda	frameCounter
	lsr	a
	lsr	a
	lsr	a
	and	#3
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CC48:
	lda	#6
	jmp	DrawLuciaObj
; End of function LuciaNormalObj


; =============== S U B R O U T I N E =======================================


LuciaLvlEndDoorObj:
	lda	roomChangeTimer
	cmp	#35		; turn off lucia's sprite to simulate her
	bcc	locret_CC58	; going through the door
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

locret_CC58:
	rts
; End of function LuciaLvlEndDoorObj


; =============== S U B R O U T I N E =======================================


LuciaDoorwayObj:
	lda	roomChangeTimer
	and	#4	; flash sprite on and off every 4 frames
	beq	locret_CC64
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

locret_CC64:
	rts
; End of function LuciaDoorwayObj


; =============== S U B R O U T I N E =======================================


LuciaDyingObj:
	ldx	roomChangeTimer
	cpx	#$5A
	bcs	LuciaDoorwayObj
	cpx	#$54
	bcc	loc_CC74
	lda	#6
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CC74:
	lda	#0
	sta	spriteAttrs
	lda	#$E0
	sta	spriteTileNum
	jsr	DrawObjNoOffset
	lda	spriteX
	clc
	adc	#$10
	ldx	objDirection
	bpl	loc_CC8B
	sec
	sbc	#$20

loc_CC8B:
	sta	spriteX
	lda	#$E2
	sta	spriteTileNum
	jmp	Write16x16SpriteToOAM
; End of function LuciaDyingObj


; =============== S U B R O U T I N E =======================================


LuciaClimbingObj:
	lda	joy1Edge
	bpl	loc_CC9B
	jmp	loc_CD0E
; ---------------------------------------------------------------------------

loc_CC9B:
	jsr	GetLuciaSpeedTblOffset
	lda	luciaXSpeedTbl,x
	sta	objXSpeed
	lda	luciaYSpeedTbl,x
	sta	objYSpeed
	jsr	SetObjDirection
	lda	objXSpeed
	beq	loc_CCBD
	lda	objYPosLo
	bmi	loc_CCBD
	jsr	GetObjMetatile
	cmp	#$24
	bcc	loc_CCBD
	jmp	loc_CD01
; ---------------------------------------------------------------------------

loc_CCBD:
	lda	objYSpeed
	bmi	loc_CCE1
	jsr	UpdateObjYPos
	bne	loc_CD01
	ldx	objMetatile
	lda	collisionBuff,x
	cmp	#$24
	bcc	loc_CD17
	txa
	clc
	adc	#$11
	tax
	lda	collisionBuff,x
	cmp	#$24
	bcc	loc_CD17
	lda	objYPosLo
	bpl	loc_CD17
	bmi	loc_CD0E

loc_CCE1:
	jsr	UpdateObjYPos
	lda	objYPosLo
	bmi	loc_CD17
	ldx	objMetatile
	lda	collisionBuff,x
	cmp	#$24
	bcc	loc_CD17
	txa
	sec
	sbc	#$11
	tax
	lda	collisionBuff,x
	cmp	#$1F
	bcc	loc_CD01
	cmp	#$24
	bcc	loc_CD17

loc_CD01:
	lda	#$80
	sta	objYPosLo
	lda	#OBJ_LUCIA_NORMAL
	sta	objType
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CD0E:
	lda	#OBJ_LUCIA_AIR
	sta	objType
	lda	#5
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CD17:
	lda	#7
	jsr	DrawLuciaObj
	rts
; End of function LuciaClimbingObj


; =============== S U B R O U T I N E =======================================


LuciaAirObj:
	jsr	GetLuciaSpeedTblOffset
	lda	luciaXSpeedTbl,x
	sta	objXSpeed
	lda	usingWingFlag
	beq	LuciaAirLockedObj
	lda	#$E0
	sta	objYSpeed
	bit	joy1
	bmi	LuciaAirLockedObj
	lda	#0
	sta	usingWingFlag

LuciaAirLockedObj:
	jsr	SetObjDirection
	jsr	UpdateObjXPos
	lda	objYSpeed
	bmi	loc_CD4A
	jsr	CheckSolidBelow
	beq	loc_CD4A
	jsr	MetatileAlignObjY
	jmp	loc_CD58
; ---------------------------------------------------------------------------

loc_CD4A:
	jsr	UpdateObjYPos
	beq	loc_CD65
	lda	#0
	sta	objYSpeed
	sta	usingWingFlag
	jmp	loc_CD65
; ---------------------------------------------------------------------------

loc_CD58:
	lda	#$A
	sta	objTimer
	lda	#OBJ_LUCIA_NORMAL	; normial lucia
	sta	objType
	lda	#4
	jmp	DrawLuciaObj
; ---------------------------------------------------------------------------

loc_CD65:
	lda	objYSpeed
	bit	joy1		; jump should be floatier when you're holding A
	bmi	loc_CD6E
	clc
	adc	#$C

loc_CD6E:
	clc	; gravity when A is pressed
	adc	#7
	bmi	loc_CD79
	cmp	#$40
	bcc	loc_CD79
	lda	#$40

loc_CD79:
	sta	objYSpeed
	lda	#5
	jmp	DrawLuciaObj
; End of function LuciaAirObj

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
; ---------------------------------------------------------------------------

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

; ---------------------------------------------------------------------------
	incl	"sound.asm"	; sound engine & sound data

; ---------------------------------------------------------------------------
	org	$FFFA		; vector table
	dw	NMIVector
	dw	ResetVector
	dw	IRQVector
	
	end
