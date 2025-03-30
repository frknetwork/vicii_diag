            * = $43 "crom"
crom:       .word // Store the location of the character ROM in ZP
            * = $45 "cdest1"
cdest1:     .word // Character ROM location for Bank 1
            * = $FD "cdest3"
cdest3:     .word // Character ROM location for Bank 3

            * = $0400 "Bank0"
bank0:
            .text "bank 0                                  "
            .text "press space to switch banks             "
            .text "f1 to switch character sets             "
            .text "any other key to exit                   "
            .text "                                        "
            .fill 256,i  // Write out the full character set.
            .fill 544,'0'

BasicUpstart2(start)
        	* = $0810 "Code"
            .const BANK_SELECT = $DD00
            .const CURRENT_BANK = $02
start:
            sei // Disable interrupts
            // Copy character ROM to locations where banks
            // 1 and 3 can access the data.
            // Map the character ROM into CPU readable space
            lda 1
            and #$FB
            sta 1

            // Set up pointers to the data we want to copy in ZP
            lda #0
            sta crom
            sta cdest1
            sta cdest3
            lda #$D0 // Character ROM is at $D000
            sta crom + 1
            lda #$50 // Bank 1 will look for char set at $5000
            sta cdest1 + 1
            lda #$D0 // Bank 3 will look for char set at $D000
            sta cdest3 + 1
            ldy #0
cloop:      lda (crom),y
            sta (cdest1),y
            sta (cdest3),y
            iny
            bne cloop
            inc crom + 1
            inc cdest1 + 1
            inc cdest3 + 1
            lda #$DF
            cmp crom + 1
            bne cloop

            // Map the character ROM back out of CPU space so we can
            // access IO registers
            lda 1
            ora #$04
            sta 1

            // Re-enable interrupts
            cli

            // There are 2 bank select bits in the bottom
            // 2 bits of $DD00. They are active LOW, so
            // Bank 0 = both bits on, bank 1 = bottom bit off, etc.
            // Init our current bank to bank 0 (#3) 
init:       lda #3
            sta CURRENT_BANK
loop:
            lda BANK_SELECT
            and #$FC
            ora CURRENT_BANK
            sta BANK_SELECT
poll:       jsr $FFE4        // Calling KERNAL GETIN 
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

notspace:   cmp #$85 // F1 key
            bne notf1
            lda $D018
            eor #2
            sta $D018
            jmp loop
notf1:
exit:
            // TODO flip back to bank 0 and charter set 1
            rts  // Return to basic

            * = $4400 "Bank1"
bank1:
            .text "bank 1                                  "
            .text "press space to switch banks             "
            .text "any other key to exit                   "
            .text "f1 to switch character sets             "
            .text "                                        "
            .fill 256,i  // Write out the full character set.
            .fill 544,'1'

            * = $8400 "Bank2"
bank2:
            .text "bank 2                                  "
            .text "press space to switch banks             "
            .text "any other key to exit                   "
            .text "f1 to switch charcater sets             "
            .text "                                        "
            .fill 256,i  // Write out the full character set.
            .fill 544,'2'

            * = $C400 "Bank3"
bank3:
            .text "bank 3                                  "
            .text "press space to switch banks             "
            .text "f1 to switch character sets             "
            .text "any other key to exit                   "
            .text "                                        "
            .fill 256,i  // Write out the full character set.
            .fill 544,'3'
