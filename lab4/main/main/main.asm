;
; AssemblerApplication1.asm
;
; Created: 2024-12-12 08:19:16
; Author : maxve266
;

; Replace with your application code
    
; --- main.asm

.equ VMEM_SZ = 5    ; #rows on display
.equ AD_CHAN_X   = 0    ; ADC0=PA0, PORTA bit 0 X-led
.equ AD_CHAN_Y   = 1    ; ADC1=PA1, PORTA bit 1 Y-led
.equ GAME_SPEED  = 150 ; inter-run delay (millisecs)
.equ PRESCALE = 7    ; AD-prescaler value
.equ BEEP_PITCH  = 8 ; Victory beep pitch
.equ BEEP_LENGTH = 6 ; Victory beep length
    
; ---------------------------------------
; --- Memory layout in SRAM
.dseg
.org SRAM_START
POSX: .byte 1 ; Own position
POSY: .byte 1
TPOSX: .byte 1 ; Target position
TPOSY: .byte 1
LINE: .byte 1 ; Current line    
VMEM: .byte VMEM_SZ ; Video MEMory
SEED: .byte 1 ; Seed for Random


; ---------------------------------------
; --- Macros for inc/dec-rementing
; --- a byte in SRAM
.macro INCSRAM ; inc byte in SRAM
    lds r16,@0
    inc r16
    sts @0,r16
.endmacro

.macro DECSRAM ; dec byte in SRAM
    lds r16,@0
    dec r16
    sts @0,r16
.endmacro

; ---------------------------------------
; --- Code
.cseg
	.org $0
	jmp START
	.org INT0addr
	jmp MUX


START:
; ***         sätt stackpekaren, vital
	ldi    r16, HIGH(RAMEND)
	out    sph, r16
	ldi    r16, LOW(RAMEND)
	out    spl, r16

	call HW_INIT    
	call WARM
	;ldi r16, 10 sts VMEM+0, r16
	;ldi r16, 34 sts VMEM+1, r16
	;ldi r16, 19 sts VMEM+2, r16
	;ldi r16, 03 sts VMEM+3, r16
	;ldi r16, 44 sts VMEM+4, r16
RUN:
	call JOYSTICK
	call ERASE_VMEM
	call UPDATE
	call HIT_CHECK
	;*** Vänta en stund så inte spelet går för fort ***
	ldi r16, GAME_SPEED
	rcall DELAY
	jmp RUN

;*** Avgör om träff    
HIT_CHECK:
	push r16
	push r17
CHECK_Y_AXIS: 
	lds r16,POSY
	lds r17,TPOSY
	cp r16, r17
	brne DONE_HIT
	CHECK_X_AXIS:
	lds r16,POSX
	lds r17,TPOSX
	cp r16,r17
	brne DONE_HIT
	HIT:
	ldi r16, BEEP_LENGTH
	call BEEP
	call WARM
	DONE_HIT:
	pop r17
	pop r16
	ret

; ---------------------------------------
; --- Multiplex display

DELAY:
	sbi PORTB,7 ; Sista porten är victory sound
	ldi r19, $0e
	delayYttreLoop:
	ldi r18, BEEP_PITCH ;
	delayInreLoop:
	dec r18
	brne delayInreLoop
	dec r16
	brne delayYttreLoop
	cbi PORTB,7
	dec r19
	brne delayyttreloop
	ret

; ---------------------------------------
; --- BEEP(r16) r16 half cycles of BEEP-PITCH
BEEP:    
;*** skriv kod för ett ljud som ska markera träff ***
	ldi    r27, BEEP_LENGTH
BEEP_LOOP:
	sbi    PORTD,5
	call DELAY
	cbi    PORTD,5
	ldi    r16,GAME_SPEED
	call DELAY
	dec    r27
	brne BEEP_LOOP
	ret

MUX:
	push ZH
	push ZL
	push r16
	push r17
	push r18
	in    r18,SREG
	push r18
GET_LINE:
	ldi    ZH,HIGH(LINE)
	ldi    ZL,LOW(LINE)
	ld    r16,Z
	lsl    r16    ;skiftar värdet åt vänster för att kunna skickas ut på rätt port (A2-A4)
	lsl    r16
	clr    r18
	out    PORTB,r18
	out    PORTA,r16
	lsr    r16    ;Skiftar tillbaka värdet för att räkna upp
	lsr    r16
	inc    r16
	cpi    r16,5
	brne INC_LINE
RESET_LINE:
	clr    r16
INC_LINE:
	st    Z,r16
	SET_DISPLAY:
	ldi    ZH,HIGH(VMEM)
	ldi    ZL,LOW(VMEM)
	add    ZL,r16
	adc    ZH,r18
	ld    r17,Z
	lsl    r16
	lsl    r16
	out    PORTA,r16
	out    PORTB,r17
	INCSRAM SEED
MUX_END:
	pop    r18
	out    SREG,r18
	pop    r18
	pop    r17
	pop    r16
	pop    ZL
	pop    ZH
	reti
    
ADC10:         ; initiate AD

	mov r16, r17
	out ADMUX, r16
	cbi ADMUX, ADLAR
    
CONVERT10:
	sbi ADCSRA, ADSC ; Starts convertion
WAIT10:
	sbic ADCSRA, ADSC
	jmp WAIT10      ; Waits for AD to finnish converting
	in r16, ADCL    ; first 8-bits
	in r17, ADCH    ; last 2-bits
	ret


;*** skriv kod som ökar eller minskar POSX beroende ***
;*** på insignalen från A/D-omvandlaren i X-led... ***
INPUT_X:
	push ZH
	push ZL
	push r16
	push r17
	;call PUSH_RUTINE

	ldi r17,AD_CHAN_X
	call ADC10
	cpi r17, $00
	brne CHECK_INC_X
	INCSRAM POSX
	jmp DONE_X
	CHECK_INC_X:
	cpi r17, $03
	brne DONE_X
	DECSRAM POSX
	DONE_X:
	pop r17
	pop r16
	pop ZL
	pop ZH
	ret

;*** ...och samma för Y-led             ***
INPUT_Y:
	push ZH
	push ZL
	push r16
	push r17
	;call PUSH_RUTINE

	ldi r17,AD_CHAN_Y
	call ADC10
	cpi r17, $00
	brne CHECK_INC_Y
	DECSRAM POSY
	jmp DONE_Y
	CHECK_INC_Y:
	cpi r17, $03
	brne DONE_Y
	INCSRAM POSY
	DONE_Y:
	pop r17
	pop r16
	pop ZL
	pop ZH
	ret
	;call POP_RUTINE;


JOYSTICK:    
	call INPUT_X
	call INPUT_Y    

JOY_LIM:
	call LIMITS    ; don't fall off world!
	ret

; ---------------------------------------
; --- LIMITS Limit POSX,POSY coordinates    
; --- Uses r16,r17
LIMITS:
	lds r16,POSX ; variable
	ldi r17,7    ; upper limit+1
	call POS_LIM    ; actual work
	sts POSX,r16
	lds r16,POSY ; variable
	ldi r17,5    ; upper limit+1
	call POS_LIM    ; actual work
	sts POSY,r16
	ret

POS_LIM:
	ori r16,0    
	brmi POS_LESS ; POSX neg => add 1
	cp r16,r17    ; past edge
	brne POS_OK
	subi r16,2
	POS_LESS:
	inc r16    
	POS_OK:
	ret

LIMITS_T:
	lds r16,TPOSX ; variable
	ldi r17,7    ; upper limit+1
	call POS_LIM_T    ; actual work
	sts TPOSX,r16
	lds r16,TPOSY ; variable
	ldi r17,5    ; upper limit+1
	call POS_LIM_T    ; actual work
	sts TPOSY,r16
	ret

POS_LIM_T:
	ori r16,0    
	brmi POS_LESS_T ; POSX neg => add 1
	cp r16,r17    ; past edge
	brne POS_OK_T
	subi r16,2
	POS_LESS_T:
	inc r16    
	POS_OK_T:
	ret

; ---------------------------------------
; --- UPDATE VMEM
; --- with POSX/Y, TPOSX/Y
; --- Uses r16, r17
UPDATE:    
	clr ZH
	ldi ZL,LOW(POSX)
	call SETPOS
	clr ZH
	ldi ZL,LOW(TPOSX)
	call SETPOS
	ret

; --- SETPOS Set bit pattern of r16 into *Z
; --- Uses r16, r17
; --- 1st call Z points to POSX at entry and POSY at exit
; --- 2nd call Z points to TPOSX at entry and TPOSY at exit
SETPOS:
	ld r17,Z+  ; r17=POSX

	call SETBIT    ; r16=bitpattern for VMEM+POSY
	ld r17,Z    ; r17=POSY Z to POSY
	ldi ZL,LOW(VMEM)
	add ZL,r17    ; *(VMEM+T/POSY) ZL=VMEM+0..4
	ld r17,Z    ; current line in VMEM
	or r17,r16    ; OR on place
	st Z,r17    ; put back into VMEM
	ret
		
	; --- SETBIT Set bit r17 on r16
	; --- Uses r16, r17
SETBIT:
	ldi r16,$01    ; bit to shift
	SETBIT_LOOP:
	dec r17        
	brmi SETBIT_END ; til done
	lsl r16    ; shift
	jmp SETBIT_LOOP
	SETBIT_END:
	ret

; ---------------------------------------
; --- Hardware init
; --- Uses r16
HW_INIT:

;*** Konfigurera hårdvara och MUX-avbrott enligt ***
;*** ditt elektriska schema. Konfigurera     ***
;*** flanktriggat avbrott på INT0 (PD2).        ***
	clr    r16
	sts    LINE,r16
	sts    SEED,r16

	ldi    r16,(1<<ISC01)|(1<<ISC00)
	out    MCUCR,r16
	ldi    r16,(1<<INT0)
	out    GICR,r16

	ldi r16, 0xFF
	out DDRB, r16

	ldi r16, 0x20
	out DDRD, r16

	ldi r16, 0x1C
	out DDRA, r16

	ldi r16, (1<<ADEN) | 4 ; sets prescaler value
	out ADCSRA, r16

	sei        ; display on

	ret

; ---------------------------------------
; --- WARM start. Set up a new game
WARM:
;*** Sätt startposition (POSX,POSY)=(0,2)    *** 
    
	clr r16
	ldi ZH,HIGH(POSX)
	ldi ZL,LOW(POSX)   ; Clears r16, behöver nog inte pushas
	st Z, r16
	ldi r16, 2
	ldi ZH,HIGH(POSY)
	ldi ZL,LOW(POSY)
	st Z, r16

	push r16  
	push r16    
	call RANDOM    ; RANDOM returns x,y on stack
	;*** Sätt startposition (TPOSX,POSY)            *** 
	call ERASE_VMEM
	pop    r16
	sts    TPOSX, r16
	pop    r16
	sts    TPOSY, r16
	call LIMITS_T
	ret

; ---------------------------------------
; --- RANDOM generate TPOSX, TPOSY
; --- in variables passed on stack.
; --- Usage as:
; --- push r0
; --- push r0
; --- call RANDOM
; --- pop TPOSX
; --- pop TPOSY
; --- Uses r16
RANDOM:

;*** Använd SEED för att beräkna TPOSX    *** 
;*** Använd SEED för att beräkna TPOSX    *** 

; ***    ; store TPOSX 2..6
; ***    ; store TPOSY   0..4


; ---------------------------------------
; --- Erase Videomemory bytes
; --- Clears VMEM..VMEM+4

	in r16,SPH
	mov ZH,r16
	in r16,SPL
	mov ZL,r16
	lds r16,SEED
	mov    r17,r16
	mov    r18,r16
	andi r17,$07 ;x-värde
	andi r18,$05 ;y-värde
	std    Z+3,r17
	std    Z+4,r18
	ret


    
ERASE_VMEM:

	;*** Radera videominnet                    *** 
	ldi    ZH,HIGH(VMEM)
	ldi    ZL,LOW(VMEM)
	ldi r17, 5 ; kanske 5
	clr r16
	LOOP_ERASE:
	st Z+,r16
	dec r17
	brne LOOP_ERASE
	EXIT_ERASE_LOOP:
	ret