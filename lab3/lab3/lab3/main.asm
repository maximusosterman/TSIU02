
;
; lab3.asm
;
; Created: 2024-12-01 13:46:09
; Author : maxve266
;

.dseg
		TIME: .byte 4
		POS: .byte 1
.cseg
		.def seconds = r22
		.def minutes = r23
		.def digit_value = r20
		.def position = r17

		.org $0000
	jmp COLD
		.org INT0addr
	jmp INT0_VECT
		.org INT1addr
	jmp INT1_VECT

	.org INT_VECTORS_SIZE

COLD:
	ldi	r16, HIGH(RAMEND) ; Set stack
	out	SPH, r16
	ldi	r16, LOW(RAMEND)
	out	SPL, r16

	ldi r16,(1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
	out MCUCR,r16

	ldi r16,(1<<INT0)|(1<<INT1)
	out GICR,r16 

	ldi seconds, 0
	sts TIME+0,seconds
	sts TIME+1,seconds
	sts TIME+2,seconds
	sts TIME+3,seconds
	sts POS, seconds

	call HW_INIT
	ldi position, 0 ; POS ; Parmater för SELECT_DIGIT
	call SELECT_SEGMENT
	ldi digit_value, 0 ; TIME ;  ; Paramter för SET_DIGIT
	call SET_DIGIT
	sei

WAIT:
	jmp WAIT

HW_INIT:
	ldi r24, $FF 
	out DDRB, r24 
	out DDRA, r24
	clr r24
	ret

SELECT_SEGMENT:
	out PORTA, position
	ret

SET_DIGIT:
	push ZH
	push ZL
	push r21
	clr r1

	ldi	ZH, HIGH(DIGIT_LOOKUP*2)
	ldi	ZL, LOW(DIGIT_LOOKUP*2)
	add ZL, digit_value
	adc ZH, r1
	lpm r21, Z

	out PORTB, r21

	pop r21
	pop ZL
	pop ZH
	ret

INT1_VECT:
	push r16
	in r16, SREG
	push r16
	push r24
	push r18
	push position
	push digit_value


	ldi YH, HIGH(POS)
	ldi YL, LOW(POS)

	ldi ZH, HIGH(TIME)
	ldi ZL, LOW(TIME)

	ldi r24, 0
START_OF_MUX_LOOP:
	ld position, Y
	ld digit_value, Z+
	
	call SELECT_SEGMENT
	call SET_DIGIT

	st Y, r24

	inc r24
	cpi r24, 4
	brne START_OF_MUX_LOOP

	push digit_value
	push position
	push r18
	pop r24
	pop r16
	out SREG, r16
	pop r16
	reti

INT0_VECT:
	; Hanteras för att räkna sekunde 
	push r16
	in r16, SREG
	push r16
	push seconds
	push r18
	
	ldi YH, HIGH(TIME)
	ldi YL, LOW(TIME)

	; räkna upp det som Y pekar på:
	ld seconds, Y
	inc seconds

	; if- för om över 10
	cpi seconds, 10
	brne LOAD_TIME
	clr seconds
	st Y+, seconds; Bit Y ska laddas med 0
	
	; Bit Y ska laddas med +1
	ld seconds, Y
	inc seconds
	cpi seconds, 6 
	brne LOAD_TIME
	
	; räkna upp det som Y pekar på:
	clr seconds
	st Y+, seconds
	ld seconds, Y
	inc seconds

	cpi seconds, 10 
	brne LOAD_TIME
	clr seconds
	st Y+, seconds
	ld seconds, Y
	inc seconds

	cpi seconds, 6
	brne LOAD_TIME
	clr seconds
	st Y+, seconds

LOAD_TIME:
	st Y, seconds

	pop r18
	pop seconds
	pop r16
	out SREG, r16
	pop r16
	reti 


DIGIT_LOOKUP:
	.db 0b0111111, 0b0000110, 0b1011011, 0b1001111, 0b1100110, 0b1101101, 0b1111101, 0b0000111, 0b1111111, 0b1101111
