; avbrottsvektorer	
	jmp		COLD		; <--- startar alltid h�r p� rad 0
	jmp		AVB_NOLL	; k�r avbrottet (jmp inte call!!)
	jmp		AVB_ETT		; anv�nds inte just nu
; h�r finns ytterligare avbrottsvektorer
; undvik dem
.org	INT_VECTORS_SIZE

COLD:		; kallstart
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16
	; -- PORTB utg�ngar
	ldi		r16,$FF
	out		DDRB,r16
	; -- s�tt avbrottsanledning
	ldi		r16,(1<<ISC01)|(1<<ISC11)
	out		MCUCR,r16
	; -- aktivera avbrott
	ldi		r16,(1<<INT0)	; PD2
	out		GICR,r16
	; -- till�t avbrott globalt. GO!
	sei

MAIN:	
	clr		r16			; b�rja r�kna fr�n 0
	sts		$60,r16	
MAINLOOP:				; 
	clr		r16			; h�r �r programmet
	jmp		MAINLOOP	; som avbryts

/* Tre versioner av avbrott med �kande funktionalitet */

AVB_NOLL:	; f�rsta version
; som f�rst�r r16
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
; som bevarar allt inre tillst�nd
	push	r16			; fria r16 s� SREG kan l�ggas d�r
	in		r16,SREG	; spara statusflaggorna i r16
	push	r16			; s� r16 kan anv�ndas nedan

	lds		r16,$60
	inc		r16
	out		PORTB,r16
	sts		$60,r16

	pop		r16			; �terst�ll innan reti
	out		SREG,r16
	pop		r16
	reti
*/

AVB_ETT:
	reti				; n�stan enklast m�jliga avbrottsrutin
						; (�nnu enklare �r att skriva reti 
						;  direkt i avbrottsvektorerna)
	