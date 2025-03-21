BasicUpstart2(start)
			* = $1000
start: 		sei // Disable interrupts

			jsr $e544 // Clear screen
			// lda #$18 // Page stuff - TODO
			// sta $d018
			
			.const target = $0400 // The start of screen ram
            .const pagestart = $43; // Store our write location in the zero page.
			ldy #0
            lda #$00
            sta pagestart
            lda #$04
            sta pagestart + 1
headerloop:	lda text,y // Grab char y from .text into register a
			cmp #$ff   // Look for $ff
			beq headerexit   // Exit the loop when we see $ff
			sta (pagestart),y // Store register a into target + x
			iny // increment y
			jmp headerloop // jump back to the start of the loop
headerexit:
            ldy #0
            // Skip down 3 rows before writing the character set to the screen.
            clc
            lda #120
            adc pagestart
            sta pagestart

charloop:   tya    // Store y in A
            sta (pagestart),y
            iny
            cpy #0 // Compare x to 0. It's only 8 bits and will wrap.
            beq charexit
            jmp charloop

charexit:
			rts // Return to BASIC

text: 		.text "page "	
			.byte $ff

			