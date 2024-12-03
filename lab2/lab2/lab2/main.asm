;
; lab2.asm
;
; Created: 2024-11-27 17:35:42
; Author : maxve266
;


; Replace with your application code
;
; lab2.asm
;
; Created: 2024-11-24 13:53:31
; Author : maxve266
;


; Replace with your application code


.equ	T = 40
.equ	N = 50

SETUP:
	clr		r16
	clr		r1
	clr		r17
	ldi		r16, HIGH(RAMEND) ; Set stack
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16

	ldi		ZH, HIGH(MESSAGE*2)
	ldi		ZL, LOW(MESSAGE*2)
	jmp		MORSE

HW_INIT:
	ldi		r24, $ff
	out		DDRB, r24
	clr		r24
	ret
	
GET_CHAR:
	lpm		r17, Z+
	cpi		r17, 0
	ret

END_STRING:
	ldi		r17, 0
	ret

LOOKUP:
	push	ZH
	push	ZL

	subi	r17, 65
	ldi		ZH, HIGH(BTAB*2)
	ldi		ZL, LOW(BTAB*2)
	add		ZL, r17
	adc		ZH, r1
	lpm		r17, Z

	pop		ZL
	pop		ZH
	ret

SEND:
	push	r16
	push	r17
	call	GET_BIT
START_LOOP:
	cpi		r16, 1
	breq	LONG_BEEP
	call	SHORT_BEEP
CONTINUE:
	ldi		r20, N
	call	NO_BEEP
	call	GET_BIT
	cpi		r17, 0
	brne	START_LOOP
	;end loop
	pop		r17
	pop		r16
	ret

GET_BIT:
	lsl		r17
	brcs	BIT_IS_ONE
	rjmp	BIT_IS_ZERO
	ret

BIT_IS_ONE:
	ldi r16, 1
	ret

BIT_IS_ZERO:
	ldi	r16, 0
	ret

BEEP:
	sbi PORTB, 0
	ldi r18, T/2
	call DELAY
	cbi PORTB, 0
	ldi r18, T/2
	call DELAY
	dec r20
	brne BEEP
	ret

LONG_BEEP:
	ldi r20, N*3
	call BEEP
	rjmp CONTINUE

SHORT_BEEP:
	ldi r20, N
	call BEEP
	ret

NO_BEEP:
	cbi PORTB, 0
	ldi r18, T/2
	call DELAY
	cbi PORTB, 0
	ldi r18, T/2
	call DELAY
	dec r20
	brne NO_BEEP
	ret

SPACE: 
	ldi		r20, N*5
	rcall	NO_BEEP
	ret

DELAY:
	sbi PORTB,7
	push r16
	push r17
	ldi r16,10 ; Decimal bas
delayYttreLoop:
	ldi r17,$1F
delayInreLoop:
	dec r17
	brne delayInreLoop
	dec r16
	brne delayYttreLoop
	cbi PORTB,7
	pop r17
	pop r16
	ret

MESSAGE:
	.db "SOS SOS", $00

BTAB:
	.db $60, $88, $A8, $90, $40, $28, $D0, $08, $20, $78, $B0, $48, $E0, $A0, $F0, $68, $D8, $50, $10, $C0, $30, $18, $70, $98, $B8, $C8, $00

MORSE:
	push	r17
	call	HW_INIT ; Init hårdvara
	call	GET_CHAR
START_LOOP_MAIN:
	call	LOOKUP
	call	SEND
	ldi		r20, N
	call	NO_BEEP
	call	GET_CHAR
	tst		r17
	breq	END_LOOP
	cpi		r17, $20
	breq	SPACE
	jmp		START_LOOP_MAIN
	pop		r17

END_LOOP:
	jmp END_LOOP
	
