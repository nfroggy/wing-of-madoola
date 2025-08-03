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
