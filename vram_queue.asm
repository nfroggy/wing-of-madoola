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
