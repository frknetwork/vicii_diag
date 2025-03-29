            * = $43 "crom"
crom:       .word // Store the location of the character ROM in ZP
            * = $45 "cdest1"
cdest1:     .word // Character ROM location for Bank 1
//            * = $FD "cdest3"
//cdest3:     .word // Character ROM location for Bank 3

            * = $0400 "Bank0"
bank0:
            .text "bank 0                                  "
            .text "press any key to switch banks           "
            .text "                                        "
            .fill 256,i  // Write out the full character set.
            .fill 624,'0'

BasicUpstart2(start)
        	* = $2000 "Code"
            .const PAGE_SELECT = $DD00
            .const CURRENT_PAGE = $02
start: 		
            // Copy character ROM to locations where banks
            // 1 and 3 can access the data.
            // Set up pointers to the data we want to copy in ZP
            lda #0
            sta crom
            sta cdest1
//            sta cdest3
            lda $10 // Character ROM is at $1000
            sta crom + 1
            lda $50 // Bank 1 will look for char set at $5000
            sta cdest1 + 1
            lda $D0 // Bank 3 will look for char set at $D000
//            sta cdest3 + 1
            ldy #0         
cloop:      lda (crom),y    
            sta (cdest1),y
//            sta (cdest3),y
            iny
            bne cloop
            inc crom
            inc cdest1
//            inc cdest3
            lda #$1f
            cmp crom
            bne cloop 

            // There are 2 page select bits in the bottom
            // 2 bits of $DD00. They are active LOW, so
            // Page 0 = both bits on, Page 1 = bottom bit off, etc.
            // Init our current page to page 0 (#3) 
init:       lda #3
            sta CURRENT_PAGE
loop:
            lda PAGE_SELECT
            and #$FC
            ora CURRENT_PAGE
            sta PAGE_SELECT
poll:       jsr $FFE4        // Calling KERNAL GETIN 
            beq poll
            dec CURRENT_PAGE
            // If we decrement past 0, jump back to the beginning and init back
            // to page 0
            lda #$FF
            cmp CURRENT_PAGE
            beq init
            jmp loop
exit: // TODO create a way to get here
            rts  // Return to basic

// Todo load character set for banks 1 and 3

            * = $4400 "Bank1"
bank1:
            .text "bank 1                                  "
            .text "press any key to switch banks           "
            .text "                                        "
            .fill 256,i  // Write out the full character set.
            .fill 624,'1'

            * = $8400 "Bank2"
bank2:
            .text "bank 2                                  "
            .text "press any key to switch banks           "
            .text "                                        "
            .fill 256,i  // Write out the full character set.
            .fill 624,'2'

            * = $C400 "Bank3"
bank3:
            .text "bank 3                                  "
            .text "press any key to switch banks           "
            .text "                                        "
            .fill 256,i  // Write out the full character set.
            .fill 624,'3'
