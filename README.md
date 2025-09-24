# Ne8zip

A modernized CHIP-8 that doesn't suck.

## What's This?

Started on Zig Day 2025 when classic CHIP-8's instruction set became too much of a hassle. Think CHIP-8 but with actual memory, proper graphics, and syscalls that make sense.

## The Good Stuff

- 64KB memory (not 4KB like some peasant)
- 800×450 RGB display instead of that green monochrome nonsense
- 24-bit instructions with proper formats
- A stack.
- Syscalls for graphics, audio, input, sprites
- Mouse support (it's 2025, folks)

## Memory Layout

```plain
0x00000  General RAM     (40KB)
0x0A000  Data Stack      (8KB) 
0x0C000  Call Stack      (4KB, hands off)
0x0D000  Program Code    (44KB)
0x18000  Void            (don't go here)
```

## Instructions That Matter

**Data**: LOAD, STORE, PUSH, POP, MOVE, COPY  
**Math**: ADD, SUB, MUL, DIV, AND, OR, XOR, SHL, SHR  
**Flow**: BEQ, BNE, BLT, BGT, CALL, RET, JUMP  
**System**: SYSCALL (the star of the show)

## Syscalls Worth Knowing

```plain
0x00  Draw pixel       0x20  Check key
0x01  Draw sprite      0x22  Mouse position  
0x02  Draw line        0x30  Play tone
0x03  Draw rectangle   0x32  Play MIDI note
0x05  Clear screen     0x40  Set timer
0x10  New sprite       0x46  Exit program
```

## Hello World

```asm
COPY R1, 400       # center x
COPY R2, 225       # center y  
COPY R3, 0xFF0000  # red
SYSCALL 0x00       # draw pixel
SYSCALL 0x46       # exit
```

## Registers

- R0: Always zero
- R1-R13: Your playground
- R14: Stack pointer
- R15: Return address for calls

## Implementation Notes

24-bit instructions, 60Hz target, crash on stupid operations.
