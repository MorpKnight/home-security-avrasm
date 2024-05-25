;-----------------------
; MASTER CODE 
;-----------------------
#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main
.global again


main:
  ;--------------------------------------------------------------
  RCALL I2C_init      ;initialize TWI module
  ;--------------------------------------------------------------
  LDI R26, 0xA0       ;inital byte to be transmitted (on LED in slave PD)
  RCALL init_serial
  CLR R25
  CLR R29
  CLR R30
  LDI R25, 0
  LDI R29, 0
  LDI R30, 6

again:
 ;--------------------------------------------------------------
  ;Sensor Read
  ;--------------------------------------------------------------
  SBI DDRB, 1 ;pin PB0 as o/p
  CBI PORTB, 1 ;first, send low pulse
  RCALL delay_20ms ;for 20ms
  SBI PORTB, 1 ;then send high pulse
  ;-----------------------------------------------------------------
  ;wait for response signal
  ;---------------
  CBI DDRB, 1 ;pin PB0 as i/p
  w1: SBIC PINB, 1
  RJMP w1 ;wait for DHT11 low pulse
  w2: SBIS PINB, 1
  RJMP w2 ;wait for DHT11 high pulse
  w3: SBIC PINB, 1
  RJMP w3 ;wait for DHT11 low pulse
;-----------------------------------------------------------------
  RCALL DHT11_reading ;read humidity (1st byte of 40-bit data)
  MOV R19, R18
  RCALL DHT11_reading
  RCALL DHT11_reading ;read temp (3rd byte of 40-bit data)
;-----------------------------------------------------------------
;--------------------------------------------------------
; I2C for Sensor Read Result
;--------------------------------------------------------
sendResult: 
  RCALL I2C_start     ;transmit START condition
  LDI R27, 0b10010000 ;SLA(1001000) + W(0)
  RCALL I2C_write     ;write slave address SLA+W
  MOV R26, R18
  ; RCALL jamDigital
  RCALL I2C_write2    ;write data byte
  RCALL I2C_stop      ;transmit STOP condition

  ;--------------------------------------------------------

  RCALL delay_50usec    ;delay 50usec second
  RJMP again          ;repeat transmission
  ;==============================================================

delay_timer0: ;50 usec delay via Timer 0
  ;---------------------------------------------------------
  CLR R20
  OUT TCNT0, R20 ;initialize timer0 with count=0
  LDI R20, 100
  OUT OCR0A, R20 ;OCR0 = 100
  LDI R20, 0b00001010
  OUT TCCR0B, R20 ;timer0: CTC mode, prescaler 8
  ;---------------------------------------------------------
  lo2: IN R20, TIFR0 ;get TIFR0 byte & check
  SBRS R20, OCF0A ;if OCF0=1, skip next instruction
  RJMP lo2 ;else, loop back & check OCF0 flag
  ;---------------------------------------------------------
  CLR R20
  OUT TCCR0B, R20 ;stop timer0
  ;---------------------------------------------------------
  LDI R20, (1<<OCF0A)
  OUT TIFR0, R20 ;clear OCF0 flag
  RET

jamDigital:
  INC R25
  CPI R25, 60
  BRNE jamDigital_detik
  LDI R25, 0
  INC R29

jamDigital_detik:
  CPI R29, 60
  BRNE jamDigital_menit
  LDI R29, 0
  INC R30

jamDigital_menit:
  CPI R30, 24
  BRNE jamDigital
  LDI R30, 0

jamDigital_jam:
  CPI R30, 18
  BRGE kirimData
  CPI R30, 6
  BRLO kirimData
  RJMP again
  RET

kirimData:
  RCALL I2C_start
  LDI R27, 0b10010000
  RCALL I2C_write
  CPI R26, 0x0F
  BRNE again
  LDI R26, 0xFF
  RCALL I2C_write2
  RET

delay_50usec: ;50 usec delay via timer1
  ;-------------------------------------------------------
  CLR R20
  OUT TCNT0, R20 ;initialize timer0 with count=0
  LDI R20, 100
  OUT OCR0A, R20 ;OCR0 = 100
  LDI R20, 0b00001010
  OUT TCCR0B, R20 ;timer0: CTC mode, prescaler 8
  ;---------------------------------------------------------
  LOOP2: IN R20, TIFR0 ;get TIFR0 byte & check
  SBRS R20, OCF0A ;if OCF0=1, skip next instruction
  RJMP LOOP2 ;else, loop back & check OCF0 flag
  ;---------------------------------------------------------
  CLR R20
  OUT TCCR0B, R20 ;stop timer0
  ;---------------------------------------------------------
  LDI R20, (1<<OCF0A)
  OUT TIFR0, R20 ;clear OCF0 flag
  RET

I2C_init:
  LDI R21, 0
  STS TWSR, R21   ;prescaler 1
  LDI R21, 35     ;division factor = 35
  STS TWBR, R21   ;
  LDI R21, (1<<TWEN)
  STS TWCR, R21   ;enable TWI
  RET
  
I2C_start:
  LDI R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
  STS TWCR, R21         ;transmit START condition
  wt1:
    LDS R21, TWCR
    SBRS R21, TWINT     ;TWI interrupt = 1?
    RJMP wt1            ;no, wait for end of transmission
  RET

I2C_write:
  STS TWDR, R27         ;copy SLA+W into data register
  LDI R21, (1<<TWINT)|(1<<TWEN)
  STS TWCR, R21         ;transmit SLA+W
  wt2:
    LDS R21, TWCR
    SBRS R21, TWINT
    RJMP wt2            ;wait for end of transmission
  RET

I2C_write2:
  STS TWDR, R26         ;copy data into data register
  LDI R20, (1<<TWINT)|(1<<TWEN)
  STS TWCR, R20         ;transmit data
  wt22:
    LDS R20, TWCR
    SBRS R20, TWINT
    RJMP wt22            ;wait for end of transmission
  RET

I2C_stop:
  LDI R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
  STS TWCR, R21         ;transmit STOP condition
  RET
  
DHT11_reading:
  LDI R17, 8 ;set counter for receiving 8 bits
  CLR R18 ;clear data register
;-------------------------------------------------------
w4: 
  SBIS PINB, 1
  RJMP w4 ;detect data bit (high pulse)
  RCALL delay_timer0 ;wait 50us & then check bit value
  ;-------------------------------------------------------
  SBIS PINB, 1 ;if received bit=1, skip next inst
  RJMP skp ;else, received bit=0, jump to skp
  SEC ;set carry flag (C=1)
  ROL R18 ;shift in 1 into LSB data register
  RJMP w5 ;jump & wait for low pulse
  skp:LSL R18 ;shift in 0 into LSB data register
  ;-------------------------------------------------------
  w5: SBIC PINB, 1
  RJMP w5 ;wait for DHT11 low pulse
  ;-------------------------------------------------------
  DEC R17 ;decrement counter
  BRNE w4 ;go back & detect next bit
  RET ;return to calling subroutine
;=================================================================
;delay subroutines
;=================================================================
delay_20ms: ;delay 20ms
  LDI R21, 255
  l3: LDI R22, 210
  l4: LDI R23, 2
  l5: DEC R23
  BRNE l5
  DEC R22
  BRNE l4
  DEC R21
  BRNE l3
  RET


init_serial:
  CLR R24
  STS UCSR0A, R24   ; clear UCSR0A register
  STS UBRR0H, R24   ; clear UBRR0H register  
  LDI R24, 103      ; store in UBRR0L 103 value
  STS UBRR0L, R24   ; to set baud rate 9600
  LDI R24, 1<<RXEN0 | 1<<TXEN0   ;enable RXB & TXB
  STS UCSR0B, R24
  LDI R24, 1<<UCSZ00 | 1<<UCSZ01 ;asynch, no parity, 1 stop, 8 bits
  STS UCSR0C, R24
  RET

LCD_buffer:
  LDS R28, UCSR0A
  SBRS R28, UDRE0 ;test data buffer if data can be sent
  RJMP LCD_buffer
  RET

ASCII_MSD: ;Proses mendapatkan ASCII dari MSD
  MOV R23, R16 ;save copy of result
  ANDI R16, 0xF0 ;extract & swap high-nibble
  SWAP R16
  SUBI R16, -48 ;R16 = R16 - (48) = R16 + 48
  MOV R28, R16 ;save a copy of high-byte result
  SUBI R28, 58 ;if +ve    
  BRPL A_F_D1 ;branch & add 7 to get ASCII A to F
lo1: 
  RET

ASCII_LSD: ;Proses mendapatkan ASCII dari LSD
  MOV R16, R23 ;restore copy of result
  ANDI R16, 0x0F ;extract low-nibble
  SUBI R16, -48 ;R16 = R16 - (48) = R16 + 48
  MOV R28, R16 ;save a copy of high-byte result
  SUBI R28, 58 ;if +ve
  BRPL A_F_D0 ;branch & add 7 to get ASCII A to F
loop2: 
  RET

A_F_D1:
  SUBI R16, -7 ;R16 = R16 - (7) = R16 + 7
  RJMP lo1
A_F_D0:
  SUBI R16, -7 ;R16 = R16 - (7) = R16 + 7
  RJMP loop2
  
delay_sec: ;1s delay
  LDI R20, 255
loop4: 
  LDI R21, 255
loop5: 
LDI R22, 82
loop6: 
  DEC R22
  BRNE loop6
  DEC R21
  BRNE loop5
  DEC R20
  BRNE loop4
  RET