            * = $80 "ZP"
crom:       .dword $1000 // Store the location of the character ROM in ZP
cdest1:     .dword $5000 // Character ROM location for Bank 1
cdest3:     .dword $D000 // Character ROM location for Bank 3

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
            ldy #$FF         
cloop:      lda ($80),y    
            sta $0400,y    
            dey            
            bpl cloop      

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
