;-----------------------
; SLAVE CODE 
;-----------------------
#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

main:
  RCALL init_serial
  LDI R21, 0xF0
  OUT DDRD, R21 ;port D[7:4] is o/p
  CLR R17
  CLR R18
  CLR R19
  LDI R17, 0
  LDI R18, 0
  LDI R19, 6
  CBI DDRB, 0  ; button as input
  CBI PORTB, 0 ; button pull-up disable
  CBI DDRB, 1
  CBI PORTB, 1

again: 
  ;-------------------------------------------------------
  ; I2C read
  ;-------------------------------------------------------
  RCALL I2C_init
  RCALL I2C_listen
  RCALL I2C_read
  ; MOV R16, R27
  ; RCALL jamDigital
  RCALL check_button
  RCALL checkTemp

printTemperature: 
  ;-------------------------------------------------------
  ; Print to serial monitor
  ;-------------------------------------------------------
  RCALL ASCII_MSD    ; Mendapatkan ASCII dari MSD
  RCALL LCD_buffer
  STS UDR0, R16

  RCALL ASCII_LSD    ;Mendapatkan ASCII dari LSD
  RCALL LCD_buffer   ;Subroutine untuk mengecek FLAG UDRE0
  STS UDR0, R16      ;print LSD

  LDI R16, '|'       ;
  RCALL LCD_buffer   ;Subroutine untuk mengecek FLAG UDRE0
  STS UDR0, R16      
  
  RJMP again

check_button:
  SBIC PINB, 0
  RJMP if_button_pressed
  RJMP jamDigital

if_button_pressed:
  LDI R25, 1

jamDigital:
    INC R17
    CPI R17, 60
    BRNE skipTambahMenit
    LDI R17, 0
    INC R18

skipTambahMenit:
    CPI R18, 60
    BRNE skipTambahJam
    LDI R18, 0x00
    INC R19

skipTambahJam:
    CPI R19, 24
    BRNE skipTambahHari
    LDI R19, 0

skipTambahHari:
    CPI R25, 1
    BREQ bacaData
    CPI R19, 18
    BRGE bacaData
    CPI R19, 6
    BRLO bacaData
    RJMP again
    RET

bacaData:
    MOV R16, R27
    RET

checkTemp: 
  CPI R27, 0x28
  BRSH fireDetected
  BRLT noFire
  RET

fireDetected:
  SBI PORTD, 6 ;turn on buzzer
  RCALL myDelay ;delay between led switch
  CBI PORTD, 5 ;turn on led
  RCALL myDelay ;delay between led switch
  SBI PORTD, 5 ;turn on led
  SBI PORTD, 7 ;turn on dc water pump 
  RET
;----------------------------------------------------------------
myDelay: ;3-level nested loop delay
  LDI R20, 255 ;outer loop counter
c1: 
  LDI R21, 255 ;mid loop counter
c2: 
  LDI R22, 20 ;inner loop counter 
;1s delay = 255 * 255 * 82 * 3 = 15.996.150 cycle = 1 s
c3: 
  DEC R22 ;decrement inner loop
  BRNE c3 ;Branch ke l3 jika R22 != 0
  DEC R21 ;decrement mid loop
  BRNE c2 ;Branch ke l2 jika R21 != 0 
  DEC R20 ;decrement outer loop
  BRNE c1 ;`Branch ke l1 jika R20 != 0
  RET ;return

noFire: 
  CBI PORTD, 6
  CBI PORTD, 5
  CBI PORTD, 7
  RCALL delay_sec 
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
lo2: 
  RET

A_F_D1:
  SUBI R16, -7 ;R16 = R16 - (7) = R16 + 7
  RJMP lo1
A_F_D0:
  SUBI R16, -7 ;R16 = R16 - (7) = R16 + 7
  RJMP lo2
  
delay_sec: ;1s delay
  LDI R20, 255
  l4: LDI R21, 255
  l5: LDI R22, 82
  l6: DEC R22
  BRNE l6
  DEC R21
  BRNE l5
  DEC R20
  BRNE l4
  RET

I2C_init:
  LDI R21, 0b10010000
  STS TWAR, R21 ;store slave address 0b10010000
  LDI R21, (1<<TWEN)
  STS TWCR, R21 ;enable TWI
  LDI R21, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
  STS TWCR, R21 ;enable TWI & ACK
  RET

I2C_listen:
  LDS R21, TWCR
  SBRS R21, TWINT
  RJMP I2C_listen ;wait for slave to be addressed
  RET

I2C_read:
  LDI R21, (1<<TWINT)|(1<<TWEA)|(1<<TWEN)
  STS TWCR, R21 ;enable TWI & ACK
  ;----------------------------------------------------------
  wt: LDS R21, TWCR
  SBRS R21, TWINT
  RJMP wt ;wait for data byte to be read
  ;----------------------------------------------------------
  LDS R27, TWDR ;store received byte
  RET