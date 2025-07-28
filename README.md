# Wing of Madoola disassembly

This disassembly builds a 1:1 copy of the *Wing of Madoola* PRG ROM. You will need to dump your own copy of the CHR ROM to turn this into a runnable game. The CHR ROM should be 32 KB and have an MD5 checksum of 68312a39ff2f82b5ff951d9003acdcd0. 

This code is (c) 1986 Sunsoft. I hope that they won't care since this repo can't be used to create a runnable game by itself, but I'll take it down if they ask. I place the variables/comments/other textual content in the public domain.

## Project status
At this point, there are no hardcoded addresses in the disassembly. You can add/remove/shift around stuff at will. All RAM variables/buffers, all used subroutines, and most unused subroutines have names. Most of the code is currently in one file, and some of it (especially the object and sound code) is very sparsely commented.

## Build instructions
1. Make sure you cloned the repo with `git clone --recurse-submodules` so you also pull in the assembler code.
2. Make sure you have gcc/clang and cmake installed.
3. Save your CHR ROM dump to "data/madoola.chr".
4. Run "build.sh". It will compile the assembler, assemble the PRG ROM, and combine the ROM files into a runnable .nes file. It will then verify that the .nes file matches the original game.

## Things to look out for
- Whatever assembler the developers used required manually setting instructions to use their zero-page versions, and they sometimes forgot to do this (whoever did the sound engine seems to have not realized this was a thing at all). Whenever you see an instruction that accesses a label or address prefixed with "!" (such as `stx !oamLen`), this forces the instruction to use its absolute address version instead of its zero-page version. Doing this was necessary to get the built ROM to match.
- I have chosen to call the game engine entities with associated position data, behavior code, etc "objects". For example, Lucia, the enemies, and the item pickups are all object. Meanwhile, the 8x16 movable graphics drawn by the NES hardware are called "sprites". This may be a bit confusing to fans of Nintendo terminology, as they refer to sprites as objects.
