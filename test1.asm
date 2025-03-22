BasicUpstart2(start)
			* = $1000
start: 		sei // Disable interrupts

			jsr $e544 // Clear screen
			// lda #$18 // bank stuff - TODO
			// sta $d018
			
            // Store the current screen bank in $45
            .const current_bank = $45
            lda #0
            sta current_bank

			// The start of screen ram is at $0400
            .const target_high = $04
            .const target_low = $00
            // Store our write location in the zero page.
            // $43 and $44 are suppsedly used by the BASIC INPUT routine
            // Since we're not using that they should be safe.
            .const bankstart = $43;
            lda #target_low
            sta bankstart
            lda #target_high
            sta bankstart + 1
bankfillloop:
			ldy #0
headerloop:	lda header,y // Grab char y from header into register a
			cmp #$ff   // Look for $ff
			beq headerexit   // Exit the loop when we see $ff
			sta (bankstart),y // Store register a into target + y
			iny // increment y
			jmp headerloop // jump back to the start of the loop
headerexit:
            // Write out the bank number
            ldx current_bank
            lda numbers, x
            sta (bankstart), y

            // Skip down 3 rows before writing the character set to the screen.
            clc
            lda #120
            adc bankstart
            sta bankstart

            ldy #0
charloop:   tya    // Store y in A
            sta (bankstart),y
            iny
            cpy #0 // Compare y to 0. It's only 8 bits and will wrap.
            beq charexit
            jmp charloop

charexit:
            // Add $40 to the high byte of bankstart to increment our
            // write location by 16k.
            clc
            lda #$40
            adc bankstart + 1
            sta bankstart + 1

            // Clear low byte of bankstart to start writing at top of screen.
            lda #0
            sta bankstart

            // Increment the current bank
            clc
            lda #1
            adc current_bank
            cmp #4
            beq exit
            sta current_bank
            jmp bankfillloop

exit:
            lda $DD00
            and #%11111100
            ora #%00000011
            sta $DD00

			rts // Return to BASIC
header: 	.text "bank "
			.byte $ff
numbers:    .text "0123456789"

			