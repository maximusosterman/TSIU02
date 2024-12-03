; avbrottsvektorer	
	jmp		COLD		; <--- startar alltid här på rad 0
	jmp		AVB_NOLL	; kör avbrottet (jmp inte call!!)
	jmp		AVB_ETT		; används inte just nu
; här finns ytterligare avbrottsvektorer
; undvik dem
.org	INT_VECTORS_SIZE

COLD:		; kallstart
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16
	; -- PORTB utgångar
	ldi		r16,$FF
	out		DDRB,r16
	; -- sätt avbrottsanledning
	ldi		r16,(1<<ISC01)|(1<<ISC11)
	out		MCUCR,r16
	; -- aktivera avbrott
	ldi		r16,(1<<INT0)	; PD2
	out		GICR,r16
	; -- tillåt avbrott globalt. GO!
	sei

MAIN:	
	clr		r16			; börja räkna från 0
	sts		$60,r16	
MAINLOOP:				; 
	clr		r16			; här är programmet
	jmp		MAINLOOP	; som avbryts

/* Tre versioner av avbrott med ökande funktionalitet */

AVB_NOLL:	; första version
; som förstör r16
	inc		r16
	out		PORTB,r16
	reti
/*
AVB_NOLL:	; andra version
; som bevarar r16 i SRAM
	push	r16

	lds		r16,$60
	inc		r16
	out		PORTB,r16
	sts		$60,r16

	pop		r16
	reti
*/

/*
AVB_NOLL:	; tredje version 
; som bevarar allt inre tillstånd
	push	r16			; fria r16 så SREG kan läggas där
	in		r16,SREG	; spara statusflaggorna i r16
	push	r16			; så r16 kan användas nedan

	lds		r16,$60
	inc		r16
	out		PORTB,r16
	sts		$60,r16

	pop		r16			; återställ innan reti
	out		SREG,r16
	pop		r16
	reti
*/

AVB_ETT:
	reti				; nästan enklast möjliga avbrottsrutin
						; (ännu enklare är att skriva reti 
						;  direkt i avbrottsvektorerna)
	