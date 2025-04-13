// Set up a pointer in ZP for reads
// TODO try doing this with variables and .watch
/* * = $43 "src"
src:       .word 

// Set up 2 pointers in ZP for writes
* = $45 "dest1"
dest1:     .word
* = $FD "dest3"
dest3:     .word */

.var src = $43
.watch src
.var dest1 = $45
.watch dest1
.var dest3 = $FD
.watch dest3

.const charrom = $D000
.const char1 = $5000
.const char3 = $D000
.const charset_size = $1000

.macro SetupCharsets() {
    // Copy character ROM to locations where banks
    // 1 and 3 can access the data.
    // Set up pointers to the data we want to copy in ZP
    lda #0
    sta src
    sta dest1
    sta dest3
    lda #>charrom
    sta src + 1
    lda #>char1
    sta dest1 + 1
    lda #>char3
    sta dest3 + 1

    sei // Disable interrupts
    
    // Map the character ROM into CPU readable space
    lda 1
    and #$FB
    sta 1

    // Do the actual copy
    ldy #0 // Start at offset 0
loop:       
    lda (src),y // Read a byte
    sta (dest1),y // Write it to bank 1
    sta (dest3),y // Write it to bank 3
    iny // move to the next byte
    bne loop // Loop until the index rolls back to 0
    
    // Increment the high byte of each of our pointers
    inc src + 1
    inc dest1 + 1
    inc dest3 + 1
    
    // Finish once we've copied the full character set
    lda #>(char3+charset_size)
    cmp src + 1
    bne loop 

    // Map the character ROM back out of CPU space so we can
    // access IO registers
    lda 1
    ora #$04
    sta 1

    // Re-enable interrupts
    cli
}

bankdata:
    .text @"bank \$00                                  "
    .text "press space to switch banks             "
    .text "press f1 to switch character set        "
    .text "                                        "
    .fill 256,i  // Write out the full character set.
    .fill 584, 0
.const chars_per_line = 40
.const lines = 25

.macro IncrementPointer(pointer, count) {
    lda #count
    clc
    adc pointer
    sta pointer
    lda #0
    adc pointer + 1
    sta pointer + 1
}

.macro SetupBank(fill_char, location) {
    // Set up our source and destination pointers in ZP
    lda #<location
    sta dest1
    lda #>location
    sta dest1 + 1

    lda #<bankdata
    sta src
    lda #>bankdata
    sta src + 1

    ldx #0
outloop:
    ldy #0
loop:
    lda (src),y
    bne nonzero // If we read a NULL character, write our fill character instead.
    lda #fill_char
nonzero:
    sta (dest1),y
    iny
    cpy #chars_per_line
    bne loop
    IncrementPointer(dest1, chars_per_line)
    IncrementPointer(src, chars_per_line)
    inx
    cpx #lines
    bne outloop
}

.const bank0 = $0400
.const bank1 = $4400
.const bank2 = $8400
.const bank3 = $C400

BasicUpstart2(start)
start: 		
    SetupCharsets()
    SetupBank('0', bank0)
    SetupBank('1', bank1)
    SetupBank('2', bank2)
    SetupBank('3', bank3)


    // There are 2 page select bits in the bottom
    // 2 bits of $DD00. They are active LOW, so
    // Page 0 = both bits on, Page 1 = bottom bit off, etc.
    // Init our current page to page 0 (#3) 
    .const PAGE_SELECT = $DD00
    .const CURRENT_PAGE = $02
    .const BANK_SELECT = $DD00
    .const CURRENT_BANK = $02
init:
    lda #3
    sta CURRENT_BANK
loop:
    lda BANK_SELECT
    and #$FC
    ora CURRENT_BANK
    sta BANK_SELECT
poll:
    jsr $FFE4        // Calling KERNAL GETIN 
    beq poll
    cmp #$20
    bne notspace
    dec CURRENT_BANK
    // If we decrement past 0, jump back to the beginning and init back
    // to bank 0
    lda #$FF
    cmp CURRENT_BANK
    beq init
    jmp loop

notspace:
    cmp #$85 // F1 key
    bne notf1
    lda $D018
    eor #2
    sta $D018
    jmp loop
notf1:
exit:
    // TODO Clear screen and return to bank 0
    rts  // Return to basic