;
; AssemblerApplication1.asm
;
; Created: 2024-12-08 13:18:27
; Author : maxve266

	; --- lab4spel.asm

	.equ	VMEM_SZ     = 5		; #rows on display
	.equ	AD_CHAN_X   = 0		; ADC0=PA0, PORTA bit 0 X-led
	.equ	AD_CHAN_Y   = 1		; ADC1=PA1, PORTA bit 1 Y-led
	.equ	GAME_SPEED  = 70	; inter-run delay (millisecs)
	.equ	PRESCALE    = 7		; AD-prescaler value
	.equ	BEEP_PITCH  = 20	; Victory beep pitch
	.equ	BEEP_LENGTH = 100	; Victory beep length
	
	; ---------------------------------------
	; --- Memory layout in SRAM
	.dseg
	.org	SRAM_START
POSX:	.byte	1	; Own position
POSY:	.byte 	1
TPOSX:	.byte	1	; Target position
TPOSY:	.byte	1
LINE:	.byte	1	; Current line	
VMEM:	.byte	VMEM_SZ ; Video MEMory
SEED:	.byte	1	; Seed for Random


	; ---------------------------------------
	; --- Macros for inc/dec-rementing
	; --- a byte in SRAM
	.macro INCSRAM	; inc byte in SRAM
		lds	r16,@0
		inc	r16
		sts	@0,r16
	.endmacro

	.macro DECSRAM	; dec byte in SRAM
		lds	r16,@0
		dec	r16
		sts	@0,r16
	.endmacro

	; ---------------------------------------
	; --- Code
	.cseg
	.org 	$0
	jmp	START
	.org	INT0addr
	jmp	MUX


START:
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16

	ldi		r16,$FF
	out		DDRB,r16
	out		DDRD,r16
	call	AGAIN
	call	HW_INIT	
	call	WARM
RUN:
	call	JOYSTICK
	call	ERASE_VMEM
	call	UPDATE

;*** 	Vänta en stund så inte spelet går för fort 	***
	
;*** 	Avgör om träff				 	***

	brne	NO_HIT	
	ldi	r16,BEEP_LENGTH
	call	BEEP
	call	WARM
NO_HIT:
	jmp	RUN

	; ---------------------------------------
	; --- Multiplex display
MUX:	

;*** 	skriv rutin som handhar multiplexningen och ***
;*** 	utskriften till diodmatrisen. Öka SEED.		***

	reti
		
	; ---------------------------------------
	; --- JOYSTICK Sense stick and update POSX, POSY
	; --- Uses r16
JOYSTICK:	

;*** 	skriv kod som ökar eller minskar POSX beroende 	***
;*** 	på insignalen från A/D-omvandlaren i X-led...	***

;*** 	...och samma för Y-led 				***

JOY_LIM:
	call	LIMITS		; don't fall off world!
	ret

	; ---------------------------------------
	; --- LIMITS Limit POSX,POSY coordinates	
	; --- Uses r16,r17
LIMITS:
	lds	r16,POSX	; variable
	ldi	r17,7		; upper limit+1
	call	POS_LIM		; actual work
	sts	POSX,r16
	lds	r16,POSY	; variable
	ldi	r17,5		; upper limit+1
	call	POS_LIM		; actual work
	sts	POSY,r16
	ret

POS_LIM:
	ori	r16,0		; negative?
	brmi	POS_LESS	; POSX neg => add 1
	cp	r16,r17		; past edge
	brne	POS_OK
	subi	r16,2
POS_LESS:
	inc	r16	
POS_OK:
	ret

	; ---------------------------------------
	; --- UPDATE VMEM
	; --- with POSX/Y, TPOSX/Y
	; --- Uses r16, r17
UPDATE:	
	clr	ZH 
	ldi	ZL,LOW(POSX)
	call 	SETPOS
	clr	ZH
	ldi	ZL,LOW(TPOSX)
	call	SETPOS
	ret

	; --- SETPOS Set bit pattern of r16 into *Z
	; --- Uses r16, r17
	; --- 1st call Z points to POSX at entry and POSY at exit
	; --- 2nd call Z points to TPOSX at entry and TPOSY at exit
SETPOS:
	ld	r17,Z+  	; r17=POSX
	call	SETBIT		; r16=bitpattern for VMEM+POSY
	ld	r17,Z		; r17=POSY Z to POSY
	ldi	ZL,LOW(VMEM)
	add	ZL,r17		; *(VMEM+T/POSY) ZL=VMEM+0..4
	ld	r17,Z		; current line in VMEM
	or	r17,r16		; OR on place
	st	Z,r17		; put back into VMEM
	ret
	
	; --- SETBIT Set bit r17 on r16
	; --- Uses r16, r17
SETBIT:
	ldi	r16,$01		; bit to shift
SETBIT_LOOP:
	dec 	r17			
	brmi 	SETBIT_END	; til done
	lsl 	r16		; shift
	jmp 	SETBIT_LOOP
SETBIT_END:
	ret

	; ---------------------------------------
	; --- Hardware init
	; --- Uses r16
HW_INIT:

;*** 	Konfigurera hårdvara och MUX-avbrott enligt ***
;*** 	ditt elektriska schema. Konfigurera 		***
;*** 	flanktriggat avbrott på INT0 (PD2).			***
	
	sei			; display on
	ret

	; ---------------------------------------
	; --- WARM start. Set up a new game
WARM:

;*** 	Sätt startposition (POSX,POSY)=(0,2)		***

	push	r0		
	push	r0		
	call	RANDOM		; RANDOM returns x,y on stack

;*** 	Sätt startposition (TPOSX,POSY)				***

	call	ERASE_VMEM
	ret

	; ---------------------------------------
	; --- RANDOM generate TPOSX, TPOSY
	; --- in variables passed on stack.
	; --- Usage as:
	; ---	push r0 
	; ---	push r0 
	; ---	call RANDOM
	; ---	pop TPOSX 
	; ---	pop TPOSY
	; --- Uses r16
RANDOM:
	in	r16,SPH
	mov	ZH,r16
	in	r16,SPL
	mov	ZL,r16
	lds	r16,SEED
	
;*** 	Använd SEED för att beräkna TPOSX		***
;*** 	Använd SEED för att beräkna TPOSX		***

;	***		; store TPOSX	2..6
;	***		; store TPOSY   0..4
	ret


	; ---------------------------------------
	; --- Erase Videomemory bytes
	; --- Clears VMEM..VMEM+4
	
ERASE_VMEM:

;*** 	Radera videominnet						***

	ret

	; ---------------------------------------
	; --- BEEP(r16) r16 half cycles of BEEP-PITCH
BEEP:	

;*** skriv kod för ett ljud som ska markera träff 	***

	ret			

; ------ A/D-omvandlare ------ ;
AGAIN:
	call	ADC8
	out		PORTB,r16	; (bara denna om adc8)
	out		PORTD,r17
	jmp		AGAIN

ADC10:
	ldi		r16,(0<<ADLAR)|5	; right shifted, pin PA5
	out		ADMUX,r16
	ldi		r16,(1<<ADEN)|4		; enable hardware, 1/16=125 kHz
	out		ADCSRA,r16
CONVERT10:
	sbi		ADCSRA,ADSC			; start conversion
WAIT10:
	sbic	ADCSRA,ADSC
	jmp		WAIT10
	in		r16,ADCL
	in		r17,ADCH			; JÄTTEVIKTIGT ADCH sist
	ret

ADC8:
	ldi		r16,(1<<ADLAR)|5	; left adjusted, pin PA5
	out		ADMUX,r16
	ldi		r16,(1<<ADEN)|4		; enable hardware, 1/16=125 kHz
	out		ADCSRA,r16
CONVERT8:
	sbi		ADCSRA,ADSC			; start conversion
WAIT8:
	sbic	ADCSRA,ADSC
	jmp		WAIT8
	in		r16,ADCH			; JÄTTEVIKTIGT ADCH sist
	ret

; med separat konfiguration
/*
WITH_CONF:
	call	ADCINIT
AGAINC:
	ldi		r16,3
	call	ADC8C
	out		PORTB,r16
	jmp		AGAINC*/

ADCINIT:
	sbi		ADMUX,ADLAR			; Left adjust
	ldi		r16,(1<<ADEN)|4		; enable hardware, 1/16=125 kHz
	out		ADCSRA,r16
	ret

; ADC8C  in: r16 channel
;       out: r16 8-bit result
;         
ADC8C:							; channel 0..7 in r16
	push	r17
	in		r17,ADMUX			; get current
	andi	r17,$F8				; clear channels
	or		r16,r17				; set new channel
	out		ADMUX,r16
CONVERT:
	sbi		ADCSRA,ADSC			; start conversion
WAIT:
	sbic	ADCSRA,ADSC
	jmp		WAIT
	in		r16,ADCH
	pop		r17
	ret