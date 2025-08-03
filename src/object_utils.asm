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
