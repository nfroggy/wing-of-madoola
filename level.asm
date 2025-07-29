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
