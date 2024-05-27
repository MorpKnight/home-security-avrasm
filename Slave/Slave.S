#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main

main:
  RCALL init_serial
  LDI R21, 0xF0
  OUT DDRD, R21
  CLR R17
  CLR R18
  CLR R19
  LDI R17, 0
  LDI R18, 0
  LDI R19, 6
  CBI DDRB, 0
  CBI PORTB, 0
  CBI DDRB, 1
  CBI PORTB, 1

again: 

  RCALL I2C_init
  RCALL I2C_listen
  RCALL I2C_read
  ; MOV R16, R27
  ; RCALL jamDigital
  RCALL check_button
  RCALL checkTemp

printTemperature: 

  RCALL ASCII_MSD
  RCALL LCD_buffer
  STS UDR0, R16

  RCALL ASCII_LSD
  RCALL LCD_buffer
  STS UDR0, R16

  LDI R16, 0x0A
  RCALL LCD_buffer
  STS UDR0, R16

  LDI R16, 0x0D
  RCALL LCD_buffer
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
  SBI PORTD, 6
  RCALL myDelay
  CBI PORTD, 5
  RCALL myDelay
  SBI PORTD, 5
  RET
  
myDelay:
  LDI R20, 255
c1: 
  LDI R21, 255
c2: 
  LDI R22, 20
  
c3: 
  DEC R22
  BRNE c3
  DEC R21
  BRNE c2
  DEC R20
  BRNE c1
  RET

noFire: 
  CBI PORTD, 6
  CBI PORTD, 5
  RCALL delay_sec 
  RET

init_serial:
  CLR R24
  STS UCSR0A, R24
  STS UBRR0H, R24
  LDI R24, 103
  STS UBRR0L, R24
  LDI R24, 1<<RXEN0 | 1<<TXEN0
  STS UCSR0B, R24
  LDI R24, 1<<UCSZ00 | 1<<UCSZ01
  STS UCSR0C, R24
  RET

LCD_buffer:
  LDS R28, UCSR0A
  SBRS R28, UDRE0
  RJMP LCD_buffer
  RET

ASCII_MSD:
  MOV R23, R16
  ANDI R16, 0xF0
  SWAP R16
  SUBI R16, -48
  MOV R28, R16
  SUBI R28, 58
  BRPL A_F_D1
lo1: 
  RET

ASCII_LSD:
  MOV R16, R23
  ANDI R16, 0x0F
  SUBI R16, -48
  MOV R28, R16
  SUBI R28, 58
  BRPL A_F_D0
lo2: 
  RET

A_F_D1:
  SUBI R16, -7
  RJMP lo1
A_F_D0:
  SUBI R16, -7
  RJMP lo2
  
delay_sec:
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
  STS TWAR, R21
  LDI R21, (1<<TWEN)
  STS TWCR, R21
  LDI R21, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
  STS TWCR, R21
  RET

I2C_listen:
  LDS R21, TWCR
  SBRS R21, TWINT
  RJMP I2C_listen
  RET

I2C_read:
  LDI R21, (1<<TWINT)|(1<<TWEA)|(1<<TWEN)
  STS TWCR, R21
  
  wt: LDS R21, TWCR
  SBRS R21, TWINT
  RJMP wt
  
  LDS R27, TWDR
  RET