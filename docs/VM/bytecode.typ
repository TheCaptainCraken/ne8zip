#let version = "0.0.1"
#let title = "Ne8zip Bytecode Specification"

#set page(
  paper: "a4",
  header: align(right)[#title v#version],
  numbering: "1",
  margin: 1.5cm,
)

#set text(
  font: "Libertinus Serif",
  size: 11pt,
)

#align(center, text(17pt)[
  *#title*
])

#align(center)[
  by Pietro Agnoli \
  #link("mailto:pietro_agnoli@proton.me") | #link("http://pietroagnoli.com")
]

= Introduction

This project started on Zig Day 20-09-2025 when classic CHIP-8's instruction set became too much of a hassle.
Inspired by RISC-V, I modernized the architecture with syscalls, expanded memory, and enhanced graphics.
Keeping the retro spirit alive while adding custom sprites and better I/O for a cleaner development experience.

= Architecture Overview

The Ne8zip VM features:
- *Registers:* $16$ general-purpose (`R0-R15`), R0 hardwired to zero, `R14` as stack pointer, `R15` for return addresses
- *Memory:* $64"KB"$ total, byte-addressable
- *Stack:* Dedicated data stack with push/pop operations (grows downward)
- *Display:* $800 times 450$ pixels, $24"bit"$ RGB color
- *Timing:* $60"Hz"$ timer, synchronous execution
- *Input:* Keyboard (ASCII) + mouse support
- *Audio:* Tone generator with note playback

== Data Types and Conventions

#table(
  columns: (auto, auto, auto),
  [Type], [Size], [Notes],
  [Register], [$16"bit"$], [Unsigned, wraps on overflow],
  [Memory Address], [$20"bit"$], [Max addressable: 0xFFFFFF],
  [Instruction], [$24"bit"$], [Fixed width],
  [Color], [$24"bit"$], [RGB: 0xRRGGBB],
  [Sprite ID], [$16"bit"$], [0-255],
)

*Arithmetic Operations:* All operations are unsigned with wraparound on overflow unless specified.

== Instruction Formats

All instructions are 24 bits. Fields are extracted as follows:

#let instruction_format_table() = {
  let field_cell(content, bits, high_bit, low_bit, has_right_border: false) = table.cell(
    colspan: bits,
    align: center,
    stroke: if has_right_border { (right: 0.5pt) } else { none },
    inset: 5pt,
    text(size: 11pt, weight: "medium")[
      #content \
      #text(size: 7pt, fill: rgb(50, 50, 50))[\[#high_bit:#low_bit\]]
    ],
  )

  table(
    columns: (auto, 1fr),
    align: center,
    stroke: 0.5pt,
    inset: 0pt,

    table.cell(inset: 8pt)[*Format*],
    table.cell(inset: 8pt)[*24-bit Layout*],

    table.cell(inset: 8pt)[*R-Type*],
    table.cell(inset: 0pt)[
      #table(
        columns: (1fr,) * 24,
        stroke: none,
        align: center,
        inset: 0pt,
        field_cell("opcode", 4, 23, 20, has_right_border: true),
        field_cell("rd", 4, 19, 16, has_right_border: true),
        field_cell("rs1", 4, 15, 12, has_right_border: true),
        field_cell("rs2", 4, 11, 8, has_right_border: true),
        field_cell("func", 8, 7, 0),
      )
    ],

    table.cell(inset: 8pt)[*I-Type*],
    table.cell(inset: 0pt)[
      #table(
        columns: (1fr,) * 24,
        stroke: none,
        align: center,
        inset: 0pt,
        field_cell("opcode", 4, 23, 20, has_right_border: true),
        field_cell("rd", 4, 19, 16, has_right_border: true),
        field_cell("rs1", 4, 15, 12, has_right_border: true),
        field_cell("imm[11:0]", 12, 11, 0),
      )
    ],

    table.cell(inset: 8pt)[*J-Type*],
    table.cell(inset: 0pt)[
      #table(
        columns: (1fr,) * 24,
        stroke: none,
        align: center,
        inset: 0pt,
        field_cell("opcode", 4, 23, 20, has_right_border: true), field_cell("addr[19:0]", 20, 19, 0),
      )
    ],

    table.cell(inset: 8pt)[*S-Type*],
    table.cell(inset: 0pt)[
      #table(
        columns: (1fr,) * 24,
        stroke: none,
        align: center,
        inset: 0pt,
        field_cell("opcode", 4, 23, 20, has_right_border: true), field_cell("syscall[19:0]", 20, 19, 0),
      )
    ],
  )
}

#instruction_format_table()

*Field Extraction:*
- `opcode = (instruction >> 20) & 0xF`
- `rd = (instruction >> 16) & 0xF`
- `rs1 = (instruction >> 12) & 0xF`
- `rs2 = (instruction >> 8) & 0xF`
- `func = instruction & 0xFF`
- `imm = instruction & 0xFFF` (12-bit, zero-extended)
- `addr = instruction & 0xFFFFF` (20-bit)

== Instruction Set

#table(
  columns: (auto, auto, auto, auto, auto),
  [*Opcode*], [*Mnemonic*], [*Operation*], [*Format*], [*Notes*],

  // Core Instructions
  table.cell(colspan: 5, fill: gray.lighten(80%), [*Memory & Data Movement*]),
  [0x0], [NOP], [No operation], [func=0x00], [PC += 3],
  [0x0], [MOVE], [$"rd" <- "rs1"$], [func=0x01], [Copy register],
  [0x0], [RET], [PC $<-$ R15], [func=0x02], [Return from CALL],
  [0x0], [PUSH], [MEM[--R14] $<-$ $"rs1"$ (16-bit)], [func=0x03], [Pre-decrement stack push],
  [0x0], [POP], [$"rd" <-$ MEM[R14++] (16-bit)], [func=0x04], [Post-increment stack pop],
  [0x2], [LOAD], [$"rd" <-$ MEM[$"rs1"$ + imm] (16-bit)], [I-Type], [Little-endian load],
  [0x3], [STORE], [MEM[$"rs1"$ + imm] $<-$ $"rd"$ (16-bit)], [I-Type], [Little-endian store],
  [0x4], [COPY], [$"rd" <-$ imm], [I-Type], [Load 12-bit immediate],
  [0x5], [PEEK], [$"rd" <-$ MEM[$"rs1"$ + imm] (8-bit)], [I-Type], [Zero-extended byte load],
  [0x6], [POKE], [MEM[$"rs1"$ + imm] $<-$ $"rd"$ (8-bit)], [I-Type], [Store low byte only],

  // Arithmetic
  table.cell(colspan: 5, fill: gray.lighten(80%), [*Arithmetic & Logic*]),
  [0x1], [ADD], [$"rd" <- "rs1" + "rs2"$], [func=0x00], [Wraps on overflow],
  [0x1], [SUB], [$"rd" <- "rs1" - "rs2"$], [func=0x01], [Wraps on underflow],
  [0x1], [MUL], [$"rd" <- ("rs1" times "rs2") "AND" "0xFFFF"$], [func=0x02], [Lower 16 bits only],
  [0x1], [DIV], [$"rd" <- "rs1" div "rs2"$], [func=0x03], [Division by 0 $->$ $"rd"$ = 0xFFFF],
  [0x1], [MOD], [$"rd" <- "rs1" mod "rs2"$], [func=0x08], [Modulo by 0 $->$ $"rd"$ = 0],
  [0x1], [AND], [$"rd" <- "rs1" "AND" "rs2"$], [func=0x04], [Bitwise AND],
  [0x1], [OR], [$"rd" <- "rs1" "OR" "rs2"$], [func=0x05], [Bitwise OR],
  [0x1], [XOR], [$"rd" <- "rs1" xor "rs2"$], [func=0x06], [Bitwise XOR],
  [0x1], [NOT], [$"rd" <- not "rs1"$], [func=0x07], [Bitwise NOT],
  [0x1], [SHL], [$"rd" <- "rs1" << ("rs2" "AND" "0xF")$], [func=0x09], [Logical shift left],
  [0x1], [SHR], [$"rd" <- "rs1" >> ("rs2" "AND" "0xF")$], [func=0x0A], [Logical shift right],
  [0x7], [SHLI], [$"rd" <- "rs1" << ("imm AND 0xF")$], [I-Type], [Immediate shift left],
  [0x8], [SHRI], [$"rd" <- "rs1" >> ("imm AND 0xF")$], [I-Type], [Immediate shift right],

  // Control Flow
  table.cell(colspan: 5, fill: gray.lighten(80%), [*Control Flow*]),
  [0x9], [BEQ], [if ($"rs1" == "rd"$) PC += sign_ext(imm)], [I-Type], [Branch equal],
  [0xA], [BNE], [if ($"rs1" != "rd"$) PC += sign_ext(imm)], [I-Type], [Branch not equal],
  [0xB], [BLT], [if ($"rs1" < "rd"$) PC += sign_ext(imm)], [I-Type], [Unsigned comparison],
  [0xC], [BGT], [if ($"rs1" > "rd"$) PC += sign_ext(imm)], [I-Type], [Unsigned comparison],
  [0xD], [CALL], [R15 $<-$ PC+3; PC $<-$ addr], [J-Type], [Save return address],
  [0xE], [JUMP], [PC $<-$ addr], [J-Type], [Unconditional jump],
  [0xF], [SYSCALL], [System call], [S-Type], [See syscall section],
)

*Branch Offset:* The 12-bit immediate is sign-extended: if bit 11 is set, bits [15:12] are set to 1.

== Special Registers

#table(
  columns: (auto, auto, auto),
  [Register], [Purpose], [Notes],
  [R0], [Always zero], [Read-only, writes ignored],
  [R1-R5], [Syscall parameters/returns], [Also general purpose],
  [R6-R13], [General purpose], [Free for user programs],
  [R14 (SP)], [Stack pointer], [Points to top of data stack],
  [R15 (LR)], [Link register], [Return address for CALL/RET],
)

*Stack Operations:*
- PUSH decrements R14 by 3, then stores value (pre-decrement)
- POP loads value, then increments R14 by 3 (post-increment)
- Stack grows downward (toward lower addresses)
- Always aligned to 3-byte boundaries

== System Calls

Syscalls use registers R1-R5 for parameters, R1 for return values. Unused parameters must be zero.

#table(
  columns: (auto, auto, auto, auto),
  [*Number*], [*Name*], [*Parameters*], [*Returns / Notes*],

  table.cell(colspan: 4, fill: gray.lighten(80%), [*Graphics - Basic (0x00-0x0F)*]),
  [0x00], [SYS_DRAW_PIXEL], [r1=x, r2=y, r3=color], [Clips to screen bounds],
  [0x01], [SYS_DRAW_SPRITE], [r1=sprite_id, r2=x, r3=y], [$8 times 8$ pixels],
  [0x02], [SYS_DRAW_LINE], [r1=x1, r2=y1, r3=x2, r4=y2, r5=color], [],
  [0x03], [SYS_DRAW_RECT], [r1=x, r2=y, r3=w, r4=h, r5=color], [Filled rectangle],
  [0x04], [SYS_DRAW_RECT_OUTLINE], [r1=x, r2=y, r3=w, r4=h, r5=color], [1px outline],
  [0x05], [SYS_CLEAR_SCREEN], [None], [Fill with black (0x000000)],
  [0x06], [SYS_DRAW_CIRCLE], [r1=cx, r2=cy, r3=radius, r4=color], [Filled circle],
  [0x07], [SYS_DRAW_CIRCLE_OUTLINE], [r1=cx, r2=cy, r3=radius, r4=color], [1px outline],
  [0x08], [SYS_GET_PIXEL], [r1=x, r2=y], [r1=color (0 if out of bounds)],

  table.cell(colspan: 4, fill: gray.lighten(80%), [*Sprite Management (0x10-0x1F)*]),
  [0x10], [SYS_SPRITE_NEW], [None], [r1=sprite_id (0 on failure)],
  [0x11], [SYS_SPRITE_SET_PIXEL], [r1=id, r2=x(0-7), r3=y(0-7), r4=color], [Modifies sprite in-place],
  [0x12], [SYS_SPRITE_DELETE], [r1=sprite_id], [Frees runtime sprite],
  [0x13], [SYS_SPRITE_COPY], [r1=sprite_id], [r1=new_id (0 on failure)],
  [0x14], [SYS_SPRITE_ROTATE], [r1=id, r2=dir(0=CW,1=CCW)], [r1=new_id],
  [0x15], [SYS_SPRITE_FLIP], [r1=id, r2=axis(0=H,1=V)], [r1=new_id],

  table.cell(colspan: 4, fill: gray.lighten(80%), [*Input (0x20-0x2F)*]),
  [0x20], [SYS_KEY_PRESSED], [r1=key_code], [r1=1 if pressed, 0 otherwise],
  [0x21], [SYS_KEY_RELEASED], [r1=key_code], [r1=1 if just released],
  [0x22], [SYS_GET_MOUSE_POS], [None], [r1=x, r2=y],
  [0x23], [SYS_MOUSE_CLICKED], [r1=button(0=left,1=right)], [r1=1 if clicked],

  table.cell(colspan: 4, fill: gray.lighten(80%), [*Audio (0x30-0x3F)*]),
  [0x30], [SYS_PLAY_TONE], [r1=freq(Hz), r2=duration(ms)], [Non-blocking],
  [0x31], [SYS_STOP_TONE], [None], [Stops current tone],
  [0x32], [SYS_PLAY_NOTE], [r1=MIDI_note, r2=duration(ms)], [C4=60, A4=69],
  [0x33], [SYS_SET_VOLUME], [r1=volume(0-100)], [Clamps to range],
  [0x34], [SYS_PLAY_NOISE], [r1=duration(ms)], [White noise],

  table.cell(colspan: 4, fill: gray.lighten(80%), [*System (0x40-0x4F)*]),
  [0x40], [SYS_TIMER_SET], [r1=milliseconds], [Sets countdown timer],
  [0x41], [SYS_TIMER_GET], [None], [r1=remaining_ms],
  [0x42], [SYS_TIMER_CLEAR], [None], [Clears timer done flag],
  [0x43], [SYS_SLEEP], [r1=milliseconds], [Blocks execution],
  [0x44], [SYS_RAND], [None], [r1=random(0-65535)],
  [0x45], [SYS_RAND_RANGE], [r1=min, r2=max], [r1=random(min..max)],
  [0x46], [SYS_EXIT], [r1=exit_code], [Terminates program],
)

== Memory Map

#table(
  columns: (auto, auto, auto, auto),
  [*Range*], [*Size*], [*Purpose*], [*Access*],
  [0x0000-0x4E20], [20KB], [General RAM], [Read/Write],
  [0x4E20-0x84D0], [14KB], [Stack], [Internal use only],
  [0x84D0-0xFA00], [30KB], [Program Code], [Read/Execute],
  [0xFA00-0xFFFFFF], [-], [Unmapped], [Access fault],
)

*Stack Operation Details:*
- *Data Stack:* User-accessible via PUSH/POP, grows downward from 0x0BFFE
- *Call Stack:* Managed by CALL/RET, separate from data stack
- Stack underflow (SP >= 0x0C000) halts execution
- Stack overflow (SP < 0x0A000) halts execution

*Memory Access Violations:*
- Out-of-bounds reads return 0
- Out-of-bounds writes are ignored
- Stack overflow/underflow halts execution
- Executing outside code segment halts execution

== Execution Model

1. *Initialization:*
  - PC = 0x84D0 (start of code segment)
  - SP (R14) = 0x4E20 (just above data stack)
  - All registers = 0x000000
2. *Instruction Cycle:*
  - Fetch 3 bytes at PC
  - Decode instruction
  - Execute operation
  - PC += 3 (unless branch/jump)
3. *Timing:* Target 60Hz display refresh, unlimited instruction rate
4. *Halting Conditions:*
  - SYS_EXIT syscall
  - PC outside code segment
  - Invalid opcode
  - Stack overflow (SP < 0x0A000)
  - Stack underflow (SP >= 0x0C000)

== Implementation Notes

*Sprite Storage Format:*
Each sprite is $8 times 8$ pixels. Runtime sprites (IDs $[0:255]$) can be created/modified via syscalls.

Color 0x000001 is transparent (this applies only to sprites).

*Key Codes:*
- 0x20-0x7E: ASCII printable characters
- 0x08: Backspace, 0x09: Tab, 0x0D: Enter, 0x1B: Escape
- 0x80-0x83: Arrow keys (Up, Down, Left, Right)

*Error Handling:*
Invalid operations should crash. Provide debug output for:
- Division by zero
- Invalid sprite IDs
- Memory access violations
- Stack errors
