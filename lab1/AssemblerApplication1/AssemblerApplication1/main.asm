   .equ T = 20 

	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16
	
	jmp		main

DELAY:
	sbi		PORTB,7

delayYttreLoop:
	ldi		r17,$1F

delayInreLoop: 
	dec		r17 
	brne	delayInreLoop 
	dec		r16
	brne	delayYttreLoop
	cbi		PORTB,7 
	ret		  
	clr		r16
main:

	hitta_1: 
		sbis	PINA,0
		jmp		hitta_1
		ldi		r16,T/2
		call    DELAY

	checkbit:
		sbis	PINA,0 
		jmp		hitta_1
		ldi		r16,T
		call	DELAY
	
		ldi		r20,4	
		clr		r18	






