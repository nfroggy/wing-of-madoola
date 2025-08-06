; =============== S U B R O U T I N E =======================================

; In:

; X: PPU Address high
; Y: PPU address low
;
; $85/$86: Address of text to print

PrintText:
	jsr	SetPPUAddr
	ldy	#0
.loop:
	lda	(tmpPtrLo),y	; read from text pointer
	beq	.done	; if it's 0, exit the loop
	sta	$2007	; else write to vram
	iny
	jmp	.loop	; read from text pointer
; ---------------------------------------------------------------------------

.done:
	iny
	tya
	clc
	adc	tmpPtrLo	; add the length of the string to the start pos
	sta	tmpPtrLo	; and overwrite the pointer with the result
	bcc	.return
	inc	tmpPtrHi

.return:
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
.paletteCopy:
	lda	gameSpritePalettes,x
	sta	paletteBuffer+$10,x
	lda	statusBGPalette,x
	sta	paletteBuffer,x
	dex
	bpl	.paletteCopy
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
.weaponLoop:
	ldx	tmpCount
	lda	weaponLevels,x
	beq	.skipWeapon
	sta	tmpCount2
	lda	#$90
	sta	spriteX
	lda	statusItemPalettes,x
	sta	spriteAttrs
	lda	statusItemTiles,x
	sta	spriteTileNum

.levelLoop:
	ldx	oamWriteCursor	; draw one weapon sprite for each level
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
	bne	.levelLoop

.skipWeapon:
	lda	spriteY
	sec
	sbc	#$10
	sta	spriteY
	dec	tmpCount
	bpl	.weaponLoop
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

.loop:
	lda	stageText,x
	sta	$2007	; write the "STAGE" text
	inx
	cpx	#6
	bne	.loop
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
.loop:
	lda	gameOverText,x
	sta	$2007
	inx
	cpx	#9
	bne	.loop
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

.loop:
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
	bcs	.downPressed
	lsr	a
	bcs	.upPressed
	lsr	a
	bcc	.loop
	lda	continueCursor
	sta	stageNum
	rts
; ---------------------------------------------------------------------------

.upPressed:
	lda	continueCursor
	cmp	highestReachedStageNum
	bcs	.loop
	inc	continueCursor
	bne	.playMenuSound

.downPressed:
	dec	continueCursor
	bpl	.playMenuSound
	inc	continueCursor
	beq	.loop

.playMenuSound:
	lda	#SFX_MENU
	jsr	PlaySound
	jmp	.loop
; End of function ShowContinue

; ---------------------------------------------------------------------------
continueText:
	db	'CONTINUE',0
	db	'FROM',0
	db	'-1 -',0
continueTextPtr:
	dw	continueText
