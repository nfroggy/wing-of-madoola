roomTilePtr	equ	$18
roomMetatilePtr	equ	$1a
roomChunkPtr	equ	$1c
roomScreenPtr	equ	$1e
nametablePosX	equ	$20
nametablePosY	equ	$21
endingTimer equ $20
endingCursor    equ $21
cameraXTiles	equ	$22
cameraYTiles	equ	$23
; where to start copying to in the nametable
nametableStartX	equ	$24
nametableStartY	equ	$25
; nametable write cursors
nametableWriteX	equ	$26
nametableWriteY	equ	$27
; where to start copying from the ROM
copyTileXStart	equ	$28
copyTileYStart	equ	$29
; copy source cursors
copyTileX	equ	$2a
copyTileY	equ	$2b
vramBuffEnd	equ	$2e
vramWriteCount	equ	$2f
cameraXLo	equ	$30
cameraXHi	equ	$31
cameraYLo	equ	$32
cameraYHi	equ	$33
spriteX		equ	$34
spriteY		equ	$35
luciaXPosLo	equ	$36	; not used by lucia's object directly, but referenced from other object code
luciaXPosHi	equ	$37
luciaYPosLo	equ	$38
luciaYPosHi	equ	$39
; 0 - no directions
; 1 - up
; 2 - up & right
; 3 - right
; 4 - down & right
; 5 - down
; 6 - down & left
; 7 - left
; 8 - up & left
directionPressed	equ	$3d
oamWriteCursor	equ	$42
oamWriteDirectionFlag	equ	$43
rngVal		equ	$47
objDirection	equ	$48	; $80 = facing left, $00 = facing right. low 7 bits = stunned timer
objHP		equ	$49	; the pickup item object uses this for the item type
objXPosLo	equ	$4a
objXPosHi	equ	$4b
objYPosLo	equ	$4c
objYPosHi	equ	$4d
objXSpeed	equ	$4e
objYSpeed	equ	$4f
objTimer	equ	$50
objMetatile	equ	$51
objType		equ	$52
currObjectIndex	equ	$53
currObjectOffset	equ	$54
roomNum		equ	$55
cameraXPixels	equ	$56
cameraYPixels	equ	$57
spriteAttrs	equ	$58
spriteTileNum	equ	$59
luciaProjectileCoords	equ	$5a	; (x pos, y pos) 8 times
luciaMetatile	equ	$6c
metatilePos	equ	$6d
metatileStart	equ	$6e
ppuAddrLo	equ	$6f
ppuAddrHi	equ	$70
scrollDirection	equ	$71	; 0 = up, 1 = right, 2 = down, 3 = left
dispOffsetX	equ	$72	; value to add to the object's x pos to get its sprite's onscreen pos
dispOffsetY	equ	$73	; value to add to the object's y pos to get its sprite's onscreen pos
attackTimer	equ	$74
; these are likely for some sort of unused debug feature
dbgMetatileNum	equ	$76
dbgTileX	equ	$77
dbgTileY	equ	$78
maxEnemies	equ	$7b
frameCounter	equ	$7e
pausedFlag	equ	$80
currentWeapon	equ	$81
tmpCount	equ	$82
tmpCount2	equ	$83
tmpPtrLo	equ	$85
tmpPtrHi	equ	$86
objAttackPower	equ	$87
weaponDamage	equ	$88
luciaHurtPoints	equ	$89
luciaDispX	equ	$8a
luciaDispY	equ	$8b
flashTimer	equ	$8e
weaponLevels	equ	$8f	; 7 bytes $8f - $95
bootsLevel	equ	$96
tilesetPalettePtr	equ	$97
healthLo	equ	$99
healthHi	equ	$9a
maxHealthLo	equ	$9b
maxHealthHi	equ	$9c
magicLo		equ	$9d
magicHi		equ	$9e
maxMagicLo	equ	$9f
maxMagicHi	equ	$a0
roomChangeTimer	equ	$a1
stageNum	equ	$a2
continueCursor	equ	$a3
luciaDoorFlag	equ	$a4
; 0: scroll in any direction
; 1: only scroll horizontally
; 2: don't scroll
scrollMode	equ	$a5
orbCollectedFlag	equ	$a7
highestReachedStageNum	equ	$a8
bossActiveFlag	equ	$a9
numBossObjs	equ	$aa
gamePlayedFlag	equ	$ab
; to start a maxxed out game, gamePlayedFlag must be 1 and cheatFlag must not be 2
cheatFlag	equ	$ac
hasWingFlag	equ	$ae
usingWingFlag	equ	$af
keywordDisplayFlag	equ	$b0
paletteBuffer	equ	$c0	; 32 bytes c0-df
oamLen		equ	$e4	; unused
doneFrame	equ	$f0
joy1		equ	$f1
joy2		equ	$f2
micData		equ	$f3
micEdge		equ	$f4
joy1Edge	equ	$f5
joy2Edge	equ	$f6
frameTimer	equ	$f8
mapperValue	equ	$f9	; see https://www.nesdev.org/wiki/INES_Mapper_184
joyLatchVal	equ	$fb
ppuXScrollCopy	equ	$fc
ppuYScrollCopy	equ	$fd
ppumaskCopy	equ	$fe
ppuctrlCopy	equ	$ff

; -------- tables, etc from here on out ---------
oamBuffer	equ	$200	; 256 bytes

itemCollectedFlags	equ	$308	; 8 bytes

soundRamArea	equ	$310
instPtrLo	equ	$310
instPtrHi	equ	$316
instChannel	equ	$31c
instCursor	equ	$322
instReg1	equ	$328
instReg0	equ	$32e
instTimer	equ	$334
instLoop	equ	$33a
instCtrlRegsSet	equ	$340
channelsInUse	equ	$348
apuStatusCopy	equ	$34f

bossDefeatedFlags	equ	$350	; 16 bytes

vramWriteBuff	equ	$400

collisionBuff	equ	$500

objectTable	equ	$700
