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
            
.macro SetupCharsets() {
    // Copy character ROM to locations where banks
    // 1 and 3 can access the data.
    // Set up pointers to the data we want to copy in ZP
    lda #0
    sta src
    sta dest1
    sta dest3
    lda #$10 // Character ROM is at $1000
    sta src + 1
    lda #$50 // Bank 1 will look for char set at $5000
    sta dest1 + 1
    lda #$D0 // Bank 3 will look for char set at $D000
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
    
    // Finish once we've copied all the way to $1FFF
    lda #$1f  // TODO should this be #$20?
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
    .text "bank N                                  "
    .text "press space to switch banks             "
    .text "press f1 to switch character set        "
    .text "                                        "
.var bankdatasize = 40 * 4

.macro SetupBank(fill_char, location) {
    // Set up our destination pointer in ZP
    // We'll use immediate mode for the source so no need for a pointer for it
    lda #0
    sta dest1
    lda location
    sta dest1 + 1

loop:
    ldy #bankdatasize
    lda bankdata,y
    sta (dest1),y
    dey
    bne loop
}

BasicUpstart2(start)
        	* = $1000 "Code"
start: 		
    SetupCharsets()
    // SetupBank('0', $04)
    // There are 2 page select bits in the bottom
    // 2 bits of $DD00. They are active LOW, so
    // Page 0 = both bits on, Page 1 = bottom bit off, etc.
    // Init our current page to page 0 (#3) 
    .const PAGE_SELECT = $DD00
    .const CURRENT_PAGE = $02
init:
    lda #3
    sta CURRENT_PAGE
loop:
    lda PAGE_SELECT
    and #$FC
    ora CURRENT_PAGE
    sta PAGE_SELECT
poll:
    jsr $FFE4        // Calling KERNAL GETIN 
    beq poll
    dec CURRENT_PAGE
    // If we decrement past 0, jump back to the beginning and init back
    // to page 0
    lda #$FF
    cmp CURRENT_PAGE
    beq init
    jmp loop
exit:
    // TODO Clear screen and return to bank 0
    rts  // Return to basic