


;
;
;Federico Benzi (271717)
;Leander Holm (273441)
;
;




.INCLUDE "M2560DEF.INC"

; Setup
START:
	LDI ZH, HIGH(ARRAY<<1)				; Set up Z reg
	LDI ZL, LOW(ARRAY<<1)
	LDI R26, 11							; Length of entire number sequence + 1 (maximum of 11 with current ARRAY length of 10).
										; ^ Change this to set the amount of rounds the game will last (remember to add 1)
	LDI R25, 1							; Use R25 for storing the current seq. length
	LDI R24, 0							; 1 if player was correct
	CALL Set_PortA_out_and_PortB_in		; Set up port A and B

NEXT_ROUND:
	CALL SHOW_SEQUENCE_STATE
	CALL PLAYER_TURN_STATE
	CPI R24, 1							; Check if player was correct, i.e. R24 == 1
	BRNE FAIL							; If player incorrect, go to FAIL (show FAIL blink and start over)
	CP R26, R25							; If player didn't fail AND whole sequence has been shown
	BREQ WIN_STATE						; --> WIN forever
	CALL SHOW_CORRECT_BLINK				; If player didn't fail, but game not yet finished, blink 1 x WIN, and
	RJMP NEXT_ROUND						; -->  continue game



; Blinks a LED pattern to indicate failure, and resets game
FAIL:
	PUSH R17					
	PUSH R16					
	LDI R17, 6
	LDI R16, 0b00111100			; Set up for blink pattern
FAIL_AGAIN:						; -----
	OUT PORTA, R16				;	|
	CALL SHORT_DELAY			;	| Blink pattern
	COM R16						;	|
	DEC R17						;	|
	BRNE FAIL_AGAIN				; -----
	
	LDI R16, 0xFF				;
	OUT PORTA, R16				; Switch off LEDs after blinking pattern
	POP R16
	POP R17
	RJMP START					; Jump to START to reset game


;;;;;;;;;;;;;;;;;;;;;;

WIN_STATE:						; Blinks a pattern representing victory, forever
	LDI R16, 0b01010101
	OUT PORTA, R16
	CALL SHORT_DELAY
	COM R16
	OUT PORTA, R16
	CALL SHORT_DELAY
	RJMP WIN_STATE

;;;;;;;;;;;;;;;;;;;;;;;;

SHOW_CORRECT_BLINK:				; Blinks a pattern representing correct answers for a single round
	PUSH R17
	PUSH R16
	LDI R17, 4
	LDI R16, 0b01010101				; Set up for blink pattern
SHOW_CORRECT_BLINK_AGAIN:	
	OUT PORTA, R16					; -----
	CALL SHORT_DELAY				;	|
	COM R16							;	| Blink pattern
	DEC R17							;	|
	BRNE SHOW_CORRECT_BLINK_AGAIN	; -----
	
	LDI R16, 0xFF					;
	OUT PORTA, R16					; Switch off LEDs after blinking
	POP R16							
	POP R17							
	RET								; Return

;;;;;;;;;;;;;;;;;;;;;

SHOW_SEQUENCE_STATE:							; Shows the current sequence
	PUSH R16
	PUSH R25
	INC R25										; Increment R25 (round length), so the current sequence of the round is 1 longer than last round								
	LDI ZH, HIGH(ARRAY<<1)						; New round -> reset index of Z to first element of ARRAY
	LDI ZL, LOW(ARRAY<<1)						; Because every new round should start with the first element
	CALL DELAY
BLINK:
	DEC R25
	BREQ END_SHOW_SEQUENCE						; Uses R25 to know if the entire sequence of current round has been shown
	LPM R16, Z+									; Load value from the ARRAY, and increment the pointer
	CALL CREATE_BIT_PATTERN_FROM_AND_TO_R16		; Creates the bit pattern for the LEDs from the numerical value
	COM R16										; Because the LEDs need 0 to light up
	OUT PORTA, R16
	CALL DELAY									; Give time after showing light on a LED
	LDI R16, 0xFF								; Switch off all LEDs between showings, to be able to differentiate even if
	OUT PORTA, R16								; -> same number (LED) is shown twice in a row
	CALL SHORT_DELAY
	RJMP BLINK									; Jump up and blink again.
END_SHOW_SEQUENCE:
	LDI R16, 0xFF
	OUT PORTA, R16								; Switch off LEDs
	POP R25										; Avoid side effects
	POP R16										; ------ " -------
	RET											; Return


;;;;;;;;;;;;;;;;;;;;;;;

PLAYER_TURN_STATE:								; Also uses the Z reg to compare the input with the ARRAY
	PUSH R18
	PUSH R16
	PUSH R25
	PUSH R17
	INC R25
	LDI ZH, HIGH(ARRAY<<1)
	LDI ZL, LOW(ARRAY<<1)
	LDI R18, 0									; Index of sequence element to be shown
	LDI R24, 1									; Assume player correct (R24 = 1)
GET_PLAYER_INPUT:
	LPM R16, Z+									; Get next element from sequence
	INC R18										; Incr. index of element to be shown
	CP R18, R25									; Compare length of shown sequence to current full sequence of the round
	BREQ END_PLAYERS_TURN						; Stop if all element of current turn have been shown

	CALL GET_BUTTON_PRESS_IN_R17				; Waits for button to be pressed. Result stored in R17
	CALL DELAY									; CRITICAL delay to avoid a single button press to be registered many times
	CP R16, R17									; Check whether button correct
	BRNE WRONG									; If input not correct, go to wrong
	RJMP GET_PLAYER_INPUT						; Get next input

WRONG:
	LDI R24, 0									; Sets the "player correct" bit to 0 (R24 = 0 -> player was wrong)
	RJMP END_PLAYERS_TURN
END_PLAYERS_TURN:
	POP R17										; R17 was used for the result from the button pres
	POP R25										; Get back the original current sequence length
	INC R25										; Increment it in preparation for the next round, where sequence will be 1 longer
	POP R16										; Avoid side effects
	POP R18										; ------ " -------
	RET											; Return

;;;;;;;;;;;;;;;;;;;;;;;

GET_BUTTON_PRESS_IN_R17:						; Loops until R17 != 8. When a button is pressed, the corresponding
	LDI R17, 8									; -> number will be stored in R17, so valid values are 0-7
BUTTON_LOOP:									; Skips instructions until a button is pressed
	SBIS PINB, 7
	LDI R17, 7
	SBIS PINB, 6 
	LDI R17, 6
	SBIS PINB, 5
	LDI R17, 5
	SBIS PINB, 4
	LDI R17, 4
	SBIS PINB, 3
	LDI R17, 3
	SBIS PINB, 2
	LDI R17, 2
	SBIS PINB, 1
	LDI R17, 1
	SBIS PINB, 0
	LDI R17, 0

	CPI R17, 8			
	BREQ BUTTON_LOOP							; If R17 == 8, no button was pressed -> loop again
	RET											; If R17 != a button was pressed -> return. Number of button stored in R17

;;;;;;;;;;;;;;;;;

CREATE_BIT_PATTERN_FROM_AND_TO_R16:				; Simple bit shifting to create bit pattern from numerical value
	PUSH R17
	LDI R17, 1
SHIFT:
	TST R16
	BREQ SHIFT_DONE
	LSL R17
	DEC R16
	RJMP SHIFT
SHIFT_DONE:
	MOV R16, R17
	POP R17
	RET

;;;;;;;;;;;;;;;;;; 

DELAY:
	PUSH R18
	PUSH R19
	PUSH R20
	LDI R18, 255
LOOP_1:
	LDI R19, 255
INNERLOOP_1:
	LDI R20, 30
MOSTINNERLOOP_1:
	DEC R20
	BRNE MOSTINNERLOOP_1
	DEC R19
	BRNE INNERLOOP_1
	DEC R18
	BRNE LOOP_1
	POP R20
	POP R19
	POP R18
	RET

;;;;;;;;;;;;;;;;;;;;;

SHORT_DELAY:
	PUSH R18
	PUSH R19
	PUSH R20
	LDI R18, 255
SHORT_LOOP_1:
	LDI R19, 255
SHORT_INNERLOOP_1:
	LDI R20, 8
SHORT_MOSTINNERLOOP_1:
	DEC R20
	BRNE SHORT_MOSTINNERLOOP_1
	DEC R19
	BRNE SHORT_INNERLOOP_1
	DEC R18
	BRNE SHORT_LOOP_1
	POP R20
	POP R19
	POP R18
	RET

;;;;;;;;;;;;;;;;;;;;

Set_PortA_out_and_PortB_in:
	PUSH R16
	LDI R16, 0xFF
	OUT DDRA, R16		; Set port A to output
	LDI R16, 0xFF
	OUT PORTA, R16		; Set all LEDs to off

	LDI R16, 0x00
	OUT PINB, R16
	LDI R16, 0x00
	OUT DDRB, R16		; Set port B to input
	POP R16
	RET

;;;;;;;;;;;;;;;;;;;;;;

FAKE_DELAY:
	PUSH R18
	LDI R18, 3
FAKE_LOOP_1:
	DEC R18
	BRNE FAKE_LOOP_1
	POP R18
	RET

;;;;;;;;;;;;;;;;;;,

ARRAY:												; Stores the full sequence of numbers to be used in the game
	.DB 6, 6, 4, 7, 7, 3, 5, 1, 4, 0

.EXIT