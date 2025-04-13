// Copyright 2025 Freaking Rad Kreative Network
// For terms see the LICENSE file in this project.

// Set up pointers in ZP
.const SRC_PTR = $43
.watch SRC_PTR
.const DEST_1_PTR = $45
.watch DEST_1_PTR
.const DEST_3_PTR = $FD
.watch DEST_3_PTR

.const CHAR_ROM = $D000
.const CHAR_BANK_1 = $5000
.const CHAR_BANK_3 = $D000
.const CHAR_ROM_SIZE = $1000
.const CPU_REGISTER_1 = $1
.const CPU_CHAR_ROM_MASK = $FB

.macro SetupCharsets() {
    // Copy character ROM to locations where banks
    // 1 and 3 can access the data.
    // Set up pointers to the data we want to copy in ZP
    lda #0
    sta SRC_PTR
    sta DEST_1_PTR
    sta DEST_3_PTR
    lda #>CHAR_ROM
    sta SRC_PTR + 1
    lda #>CHAR_BANK_1
    sta DEST_1_PTR + 1
    lda #>CHAR_BANK_3
    sta DEST_3_PTR + 1

    sei // Disable interrupts

    // Map the character ROM into CPU readable space
    lda CPU_REGISTER_1      // Read the register
    and #CPU_CHAR_ROM_MASK  // Zero out the bit
    sta CPU_REGISTER_1      // Write it back

    // Do the actual copy
    ldy #0
loop:       
    lda (SRC_PTR),y         // Read a byte
    sta (DEST_1_PTR),y      // Write it to bank 1
    sta (DEST_3_PTR),y      // Write it to bank 3
    iny                     // move to the next byte
    bne loop                // Loop until the index rolls back to 0

    // Increment the high byte of each of our pointers
    inc SRC_PTR + 1
    inc DEST_1_PTR + 1
    inc DEST_3_PTR + 1

    // Finish once we've copied the full character set
    lda #>(CHAR_BANK_3+CHAR_ROM_SIZE)
    cmp SRC_PTR + 1
    bne loop 

    // Map the character ROM back out of CPU space so we can
    // access IO registers
    lda CPU_REGISTER_1
    ora #~CPU_CHAR_ROM_MASK     // Turn the bit back on
    sta CPU_REGISTER_1

    // Re-enable interrupts
    cli
}

bankdata:
    .text @"bank \$00                                  "
    .text "press space to switch banks             "
    .text "press f1 to switch character set        "
    .text "                                        "
    .fill 256,i     // Display each character on screen
    .fill 584, 0    // Pad out with the current bank #
.const CHARS_PER_LINE = 40
.const LINES = 25

.macro IncrementPointer(pointer, count) {
    lda #count      // Start with the amount to add and no carry
    clc
    adc pointer     // Add the count to the low byte
    sta pointer     // Store it back
    lda #0          // Reset a
    adc pointer + 1 // Add any carry into the high byte
    sta pointer + 1 // Store it
}

.macro SetupBank(fill_char, location) {
    // Set up our source and destination pointers in ZP
    lda #<location
    sta DEST_1_PTR
    lda #>location
    sta DEST_1_PTR + 1

    lda #<bankdata
    sta SRC_PTR
    lda #>bankdata
    sta SRC_PTR + 1

    ldx #0
outloop:
    ldy #0
loop:
    lda (SRC_PTR),y     // Read from bankdata
    bne nonzero         // If we read a NULL character,
    lda #fill_char      // write our fill character instead.
nonzero:
    sta (DEST_1_PTR),y  // Store to the target
    iny
    cpy #CHARS_PER_LINE
    bne loop            // Copy lines one at a time

    // Move pointers to the next line.
    IncrementPointer(DEST_1_PTR, CHARS_PER_LINE)
    IncrementPointer(SRC_PTR, CHARS_PER_LINE)
    inx                 // Loop through all of the lines
    cpx #LINES
    bne outloop
}

.const BANK_0 = $0400
.const BANK_1 = $4400
.const BANK_2 = $8400
.const BANK_3 = $C400
.const KERNAL_GETIN = $FFE4
.const KERNAL_SCINIT = $FF81

// There are 2 bank select bits in the bottom
// 2 bits of $DD00. They are active LOW, so
// Bank 0 = both bits on, bank 1 = bottom bit off, etc.
// Init our current bank to bank 0 (#3)
// Store the current bank in ZP at address 2
.const BANK_SELECT = $DD00
.const BANK_SELECT_MASK = $FC
.const CURRENT_BANK = $02
.const SPACE_BAR = $20
.const F1_KEY = $85
.const SET_SELECT = $D018
.const SET_SELECT_MASK = $02
.const BANK_0_MASK = $03

BasicUpstart2(start)
start:
    SetupCharsets()
    SetupBank('0', BANK_0)
    SetupBank('1', BANK_1)
    SetupBank('2', BANK_2)
    SetupBank('3', BANK_3)

init:
    lda #BANK_0_MASK        // Start in bank 0
    sta CURRENT_BANK
loop:
    lda BANK_SELECT         // Grab the current state of the register
    and #BANK_SELECT_MASK   // Zero out the bits we care about
    ora CURRENT_BANK        // Set those bits to what we want
    sta BANK_SELECT         // Actually set the register
poll:
    jsr KERNAL_GETIN        // Read a key into A
    beq poll                // Keep reading until a key is actually pressed
    cmp #SPACE_BAR          // Look for spacebar
    bne notspace
    // Switch our current bank tracker to the next bank
    dec CURRENT_BANK        // Active LOW so dec instead of inc
    // If we decrement past 0 (bank 3), jump back to the beginning and
    // init back to bank 0 (#3)
    bmi init
    jmp loop

notspace:
    cmp #F1_KEY
    bne notf1
    lda SET_SELECT
    eor #SET_SELECT_MASK
    sta SET_SELECT
    jmp loop
notf1:
    // Add additional key handling here or fall thru to exit.
exit:
    jsr KERNAL_SCINIT       // Reinit the VICII and clear screen

    // Switch back to bank 0
    lda BANK_SELECT         // Grab the current state of the register
    and #BANK_SELECT_MASK   // Zero out the bits we care about
    ora #BANK_0_MASK        // Set those bits to what we want
    sta BANK_SELECT         // Actually set the register

    rts  // Return to basic