

;
; lab3.asm
;
; Created: 2024-12-01 13:46:09
; Author : maxve266
;


COLD:
	.def seconds = r22
	.def digit_value = r20
	.def mux_counter = r17

	DIGIT_LOOKUP:
		.db 0b0111111, 0b0000110, 0b1011011, 0b1001111, 0b1100110, 0b1101101, 0b1111101, 0b0000111, 0b1111111, 0b1101111

	ldi	r16, HIGH(RAMEND) ; Set stack
	out	SPH, r16
	ldi	r16, LOW(RAMEND)
	out	SPL, r16

	ldi r16,(1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
	out MCUCR,r16

	ldi r16,(1<<INT0)|(1<<INT1)
	out GICR,r16 

	ldi r16, (1<<INTF0)|(1<<INTF1)
    out GIFR, r16

	call HW_INIT
	ldi seconds, 0
	ldi mux_counter, 0 ; Parmater för SELECT_DIGIT
	call SELECT_SEGMENT
	ldi digit_value, 2 ; Paramter för SET_DIGIT
	call SET_DIGIT

WAIT:
	jmp WAIT


HW_INIT:
	ldi r24, $FF 
	out DDRB, r24 
	out DDRA, r24
	clr r24
	ret

SELECT_SEGMENT:
	out PORTA, mux_counter
	ret

SET_DIGIT:
	push ZH
	push ZL
	push r21
	clr r1

	ldi	ZH, HIGH(DIGIT_LOOKUP)
	ldi	ZL, LOW(DIGIT_LOOKUP)
	add ZL, digit_value
	adc ZH, r1
	lpm r21, Z

	out PORTB, r21

	pop r21
	pop ZL
	pop ZH
	ret

UPDATE_DISPLAY:
	mov digit_value, seconds
	call SET_digit
	ret

INT1_vect:
	push digit_value
	in digit_value, SREG
	push digit_value

	push mux_counter
	in mux_counter, SREG
	push mux_counter

	call SET_DIGIT
	inc mux_counter
	cpi mux_counter, 4
	brlo no_reset_mux
	clr mux_counter
no_reset_mux:
	call UPDATE_DISPLAY

	pop mux_counter
	out SREG, mux_counter
	pop mux_counter

	pop digit_value
	out SREG, digit_value
	pop digit_value
	reti

INT0_vect:
	; Hanteras för att räkna sekunde 
	push seconds
	in seconds, SREG
	push seconds

	inc seconds
	call UPDATE_DISPLAY

	pop seconds
	out SREG, seconds
	pop seconds
	reti 
