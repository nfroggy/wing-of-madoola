; +-------------------------------------------------------------------------+
; |                     The Wing of Madoola disassembly                     |
; |  This file is intended to be viewed with the tab size set to 8          |
; |  characters.                                                            |
; +-------------------------------------------------------------------------+

	incl	"variables.asm"	; variable definitions
	incl	"constants.asm"	; constant definitions

; ===========================================================================

	org	$8000
	
	incl	"map_data/metatiles.asm"	; Metatile layout data
	incl	"map_data/chunks.asm"		; Chunk layout data
	incl	"map_data/screens.asm"		; Screen layout data
	incl	"map_data/rooms.asm"		; Room layout data
	incl	"map_data/palettes.asm"		; Which palette number goes to each metatitle

; ---------------------------------------------------------------------------

	incl	"game.asm"		; game init, main game loop
	incl	"keyword.asm"		; keyword screen
	incl	"ending.asm"		; ending scene
	incl	"screens.asm"		; status/stage/continue screens
	incl	"utils.asm"		; utility functions
	incl	"vectors.asm"		; reset/nmi/irq vectors
	incl	"sprite_viewer.asm"	; unused debug sprite viewer
	incl	"palettes.asm"		; BG and sprite palettes
	incl	"title.asm"		; title screen
	incl	"level.asm"		; level display code
	incl	"player_utils.asm"	; spawning, moving between rooms, etc
	incl	"sprite.asm"		; code for displaying sprites
	incl	"utils2.asm"		; more utility code. mostly math, some ppu
	incl	"object_utils.asm"	; object utility code
	incl	"vram_queue.asm"	; handles reading/writing to/from vram
	incl	"lucia_objects.asm"	; all of lucia's different object code
	incl	"object_utils2.asm"	; more object utility code
	incl	"weapons.asm"		; initializes weapon objects
	incl	"lucia_draw.asm"	; handles drawing lucia and collision between lucia and other objects
	incl	"weapon_objects.asm"	; all the different weapons lucia can use
	incl	"objects.asm"		; objects that were likely made earlier in the game's development, more object utility code
	incl	"object_handler.asm"	; spawns enemies and runs each object's code
	incl	"objects2.asm"		; objects that were likely made later in the game's development
	incl	"sound.asm"		; sound engine & sound data
	incl	"padding.asm"	; garbage data at the end of the rom

; ---------------------------------------------------------------------------
	org	$FFFA		; vector table
	dw	NMIVector
	dw	ResetVector
	dw	IRQVector
	
	end
