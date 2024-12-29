#define __SFR_OFFSET 0x00 
#include "avr/io.h" 
 
.global main 

main:
  LDI R17, 0    ; counter for surprise
  CBI DDRD, 2   ; set pin d 2 as input switch
  CBI DDRD, 4   ; set pin d 4 as input PIR
  SBI DDRD, 5   ; set pin d 5 as output buzzer
  SBI DDRB, 4   ;pin PB4 o/p for lid servo
  SBI DDRB, 5   ;pin PB4 o/p for arm servo

main_loop:
  SBIC PIND, 4
  RCALL something_close
  SBIC PIND, 2 
  RCALL turn_servo
  RJMP main_loop

;=============================================================
;==================trigger buzzer=============================
;=============================================================
something_close:
  LDI R29, 15
l1:
  SBI PORTD, 5
  RCALL delay_ms_buzzer
  CBI PORTD, 5
  DEC R29
  BREQ main_loop
  RJMP l1

;=============================================================
;==================servo turning subroutine===================
;=============================================================
turn_servo:  
  INC   R17
  CPI   R17, 10
  BREQ  surprise 
;turning lid servo open
  LDI   R24, 70         ;load value 70, corresponding to 70' angle
  LDI   R20, 10         ;count to give enough cycles of PWM
l1_lid: 
  SBI   PORTB, 4
  RCALL delay_timer0_servo 
  CBI   PORTB, 4        ;send msec pulse to rotate servo
  RCALL delay_20ms      ;wait 20ms before re-sending pulse
  DEC   R20
  BRNE  l1_lid         ;go back & repeat PWM signal

;turning arm servo open
  LDI   R24, 90         ;load value 90, corresponding to 90' angle
  LDI   R20, 10         ;count to give enough cycles of PWM
l1_tas: 
  SBI   PORTB, 5
  RCALL delay_timer0_servo 
  CBI   PORTB, 5        ;send msec pulse to rotate servo
  RCALL delay_20ms      ;wait 20ms before re-sending pulse
  DEC   R20
  BRNE  l1_tas          ;go back & repeat PWM signal
  
;turning arm servo close
  LDI   R24, 30         ;load value 30, corresponding to 0' angle
  LDI   R20, 10         ;count to give enough cycles of PWM
l2_tas: 
  SBI   PORTB, 5
  RCALL delay_timer0_servo 
  CBI   PORTB, 5        ;send msec pulse to rotate servo
  RCALL delay_20ms      ;wait 20ms before re-sending pulse
  DEC   R20
  BRNE  l2_tas          ;go back & repeat PWM signal

;turning lid servo close
  LDI   R24, 30         ;load value 30, corresponding to 0' angle
  LDI   R20, 10         ;count to give enough cycles of PWM
l2_lid: 
  SBI   PORTB, 4
  RCALL delay_timer0_servo 
  CBI   PORTB, 4        ;send msec pulse to rotate servo
  RCALL delay_20ms      ;wait 20ms before re-sending pulse
  DEC   R20
  BRNE  l2_lid         ;go back & repeat PWM signal

  RET           ;go back

;=============================================================
;==================surprise song==============================
;=============================================================
surprise:
  LDI R18, 3         ; Initialize loop counter
surprise_loop:
  RCALL tone_1       ; Play tone 1
  RCALL delay_ms_small
  RCALL tone_1       ; Play tone 1
  RCALL delay_ms_small
  RCALL tone_2       ; Play tone 2
  RCALL delay_ms_small
  RCALL tone_2       ; Play tone 2
  RCALL delay_ms_small
  RCALL tone_3       ; Play tone 3
  RCALL delay_ms_small
  RCALL tone_3       ; Play tone 3
  RCALL delay_ms_small
  RCALL tone_2       ; Play tone 2
  RCALL delay_ms
  RCALL delay_ms
  RCALL delay_ms
  
  DEC R18            ; Decrement loop counter
  BRNE surprise_loop ; Repeat if not zero
  
  LDI R17, 0         ; Reset R17 (if needed for main_loop)
  RJMP main_loop     ; Jump back to main loop

;=============================================================
;==================tone subroutines===========================
;=============================================================
tone_1:
  LDI R29, 150
l12:
  SBI PORTD, 5
  RCALL delay_ms_buzzer_tone1
  CBI PORTD, 5
  DEC R29
  BRNE l12
  RET

tone_2:
  LDI R29, 150
l100:
  SBI PORTD, 5
  RCALL delay_ms_buzzer_tone2
  CBI PORTD, 5
  DEC R29
  BRNE l100
  RET

tone_3:
  LDI R29, 150
l120:
  SBI PORTD, 5
  RCALL delay_ms_buzzer_tone3
  CBI PORTD, 5
  DEC R29
  BRNE l120
  RET

;---------------------------------------------------------------
;=============================================================
;=================delay subroutines===========================
;=============================================================
delay_ms:
;--------
    LDI   R21, 255
l6: LDI   R22, 255
l7: LDI   R23, 50
l8: DEC   R23
    BRNE  l8
    DEC   R22
    BRNE  l7
    DEC   R21
    BRNE  l6
    RET
;===============================================================
delay_timer0_servo:             ;delay via Timer0
    ;-----------------------------------------------------------
    CLR   R21
    OUT   TCNT0, R21      ;initialize timer0 with count=0
    MOV   R21, R24        ;initialize output compare reg for limit
    OUT   OCR0A, R21
    LDI   R21, 0b00001100
    OUT   TCCR0B, R21     ;timer0: CTC mode, prescaler 256
    ;-----------------------------------------------------------
l3: IN    R21, TIFR0      ;get TIFR0 byte & check
    SBRS  R21, OCF0A      ;if OCF0=1, skip next instruction
    RJMP  l3              ;else, loop back & check OCF0 flag
    ;-----------------------------------------------------------
    CLR   R21
    OUT   TCCR0B, R21     ;stop timer0
    ;-----------------------------------------------------------
    LDI   R21, (1<<OCF0A)
    OUT   TIFR0, R21      ;clear OCF0 flag
    RET
;===============================================================
delay_20ms:               ;delay 20ms
    LDI   R21, 255
l4: LDI   R22, 210
l5: LDI   R23, 2
l700: DEC   R23
    BRNE  l700
    DEC   R22
    BRNE  l5
    DEC   R21
    BRNE  l4
    RET

delay_ms_buzzer:
;--------
    LDI  R21, 200
l200: LDI   R22, 60
l300: DEC   R22
    BRNE  l300
    DEC   R21
    BRNE  l200
    RET

delay_ms_buzzer_tone1:
;--------
    LDI   R21, 240
l61: LDI   R22, 90
l71: DEC   R22
    BRNE  l71
    DEC   R21
    BRNE  l61
    RET

delay_ms_buzzer_tone2:
;--------
    LDI   R21, 240
l601: LDI   R22, 60
l701: DEC   R22
    BRNE  l701
    DEC   R21
    BRNE  l601
    RET

delay_ms_buzzer_tone3:
;--------
    LDI   R21, 220
l650: LDI   R22, 60
l750: DEC   R22
    BRNE  l750
    DEC   R21
    BRNE  l650
    RET

delay_ms_small:
;--------
    LDI   R21, 200
l63: LDI   R22, 50
l73: LDI   R23, 50
l83: DEC   R23
    BRNE  l83
    DEC   R22
    BRNE  l73
    DEC   R21
    BRNE  l63
    RET