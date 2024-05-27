#define __SFR_OFFSET 0x00
#include "avr/io.h"

.global main
.global again

main:
  RCALL   I2C_init              ; Initialize I2C
  LDI     R26, 0xA0             ; Address of the slave
  RCALL   init_serial           ; Initialize serial
  CLR     R25                   ; Setting up & clearing register for seconds in jamDigital
  CLR     R29                   ; Setting up & clearing register for minutes in jamDigital
  CLR     R30                   ; Setting up & clearing register for hours in jamDigital
  LDI     R25, 0                ; Setting up & clearing register for seconds in jamDigital
  LDI     R29, 0                ; Setting up & clearing register for minutes in jamDigital
  LDI     R30, 6                ; Setting up & clearing register for hours in jamDigital

again:
  RCALL   delay_20ms            ; Delay 20ms
  CBI     DDRB, 1               ; Set pin 1 as input
  
sendResult: 
  CBI     PORTB, 1              ; Set pin 1 as low
  RCALL   I2C_start             ; Start I2C
  LDI     R27, 0b10010000         ; Address of the slave
  RCALL   I2C_write             ; Write the address of the slave
  SBIC    PINB, 1               ; Skip if the value of PINB is 0
  LDI     R26, 0xFF             ; Load the value of 0xFF to R26
  SBIS    PINB, 1               ; Skip if the value of PINB is 1
  LDI     R26, 0x00             ; Load the value of 0x00 to R26
  ; MOV     R26, R18                ; Move the data to R26
  ; RCALL jamDigital
  RCALL   I2C_write2            ; Write the data to the slave
  RCALL   I2C_stop              ; Stop I2C
  
  RCALL   delay_50usec          ; Delay 50 microseconds
  RJMP    again                 ; Jump to again
  
delay_timer0:
  CLR     R20                   ; Clear R20
  OUT     TCNT0, R20            ; Set the value of R20 to TCNT0 | Reset the timer
  LDI     R20, 100              ; Load the value of 100 to R20
  OUT     OCR0A, R20            ; Set the value of R20 to OCR0A | Set the compare value
  LDI     R20, 0b00001010       ; Load the value of 0b00001010 to R20
  OUT     TCCR0B, R20           ; Set the value of R20 to TCCR0B | Set the prescaler to 1024
  
  lo2: 
  IN      R20, TIFR0            ; Read the value of TIFR0
  SBRS    R20, OCF0A            ; Skip if the value of OCF0A is 0
  RJMP    lo2                   ; Jump to lo2
  
  CLR     R20                   ; Clear R20
  OUT     TCCR0B, R20           ; Set the value of R20 to TCCR0B | Set the prescaler to 0

  LDI     R20, (1<<OCF0A)       ; Load the value of (1<<OCF0A) to R20
  OUT     TIFR0, R20            ; Set the value of R20 to TIFR0 | Reset the timer
  RET                           ; Return

delay_50usec:

  CLR     R20                   ; Clear R20
  OUT     TCNT0, R20            ; Set the value of R20 to TCNT0 | Reset the timer
  LDI     R20, 100              ; Load the value of 100 to R20
  OUT     OCR0A, R20            ; Set the value of R20 to OCR0A | Set the compare value
  LDI     R20, 0b00001010       ; Load the value of 0b00001010 to R20
  OUT     TCCR0B, R20           ; Set the value of R20 to TCCR0B | Set the prescaler to 1024
  
  LOOP2: 
  IN      R20, TIFR0            ; Read the value of TIFR0
  SBRS    R20, OCF0A            ; Skip if the value of OCF0A is 0
  RJMP    LOOP2                 ; Jump to LOOP2
  
  CLR     R20                   ; Clear R20
  OUT     TCCR0B, R20           ; Set the value of R20 to TCCR0B | Set the prescaler to 0
  
  LDI     R20, (1<<OCF0A)       ; Load the value of (1<<OCF0A) to R20
  OUT     TIFR0, R20            ; Set the value of R20 to TIFR0 | Reset the timer
  RET                           ; Return

I2C_init:
  LDI     R21, 0                ; Load the value of 0 to R21
  STS     TWSR, R21             ; Set the value of R21 to TWSR
  LDI     R21, 35               ; Load the value of 35 to R21
  STS     TWBR, R21             ; Set the value of R21 to TWBR
  LDI     R21, (1<<TWEN)        ; Load the value of (1<<TWEN) to R21
  STS     TWCR, R21             ; Set the value of R21 to TWCR
  RET                           ; Return
  
I2C_start:
  LDI     R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)  ; Load the value of (1<<TWINT)|(1<<TWSTA)|(1<<TWEN) to R21
  STS     TWCR, R21             ; Set the value of R21 to TWCR
  wt1:  
    LDS   R21, TWCR             ; Load the value of TWCR to R21
    SBRS  R21, TWINT            ; Skip if the value of TWINT is 0
    RJMP  wt1                   ; Jump to wt1
  RET                           ; Return

I2C_write:
  STS     TWDR, R27             ; Set the value of R27 to TWDR
  LDI     R21, (1<<TWINT)|(1<<TWEN)             ; Load the value of (1<<TWINT)|(1<<TWEN) to R21
  STS     TWCR, R21             ; Set the value of R21 to TWCR
  wt2:
    LDS   R21, TWCR             ; Load the value of TWCR to R21
    SBRS  R21, TWINT            ; Skip if the value of TWINT is 0
    RJMP  wt2                   ; Jump to wt2
  RET                           ; Return

I2C_write2:
  STS     TWDR, R26             ; Set the value of R26 to TWDR
  LDI     R20, (1<<TWINT)|(1<<TWEN)             ; Load the value of (1<<TWINT)|(1<<TWEN) to R20
  STS     TWCR, R20             ; Set the value of R20 to TWCR
  wt22:
    LDS   R20, TWCR             ; Load the value of TWCR to R20
    SBRS  R20, TWINT            ; Skip if the value of TWINT is 0
    RJMP  wt22                  ; Jump to wt22
  RET                           ; Return

I2C_stop:
  LDI     R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)  ; Load the value of (1<<TWINT)|(1<<TWSTO)|(1<<TWEN) to R21
  STS     TWCR, R21             ; Set the value of R21 to TWCR
  RET                           ; Return
  
delay_20ms:
  LDI     R21, 255              ; Load the value of 255 to R21
  l3: 
  LDI     R22, 210              ; Load the value of 210 to R22
  l4: 
  LDI     R23, 2                ; Load the value of 2 to R23
  l5: 
  DEC     R23                   ; Decrement R23
  BRNE    l5                    ; Branch if not equal to l5
  DEC     R22                   ; Decrement R22
  BRNE    l4                    ; Branch if not equal to l4
  DEC     R21                   ; Decrement R21
  BRNE    l3                    ; Branch if not equal to l3
  RET                           ; Return


init_serial:
  CLR     R24                   ; Clear R24
  STS     UCSR0A, R24           ; Set the value of R24 to UCSR0A
  STS     UBRR0H, R24           ; Set the value of R24 to UBRR0H
  LDI     R24, 103              ; Load the value of 103 to R24
  STS     UBRR0L, R24           ; Set the value of R24 to UBRR0L
  LDI     R24, 1<<RXEN0 | 1<<TXEN0              ; Load the value of 1<<RXEN0 | 1<<TXEN0 to R24
  STS     UCSR0B, R24           ; Set the value of R24 to UCSR0B
  LDI     R24, 1<<UCSZ00 | 1<<UCSZ01            ; Load the value of 1<<UCSZ00 | 1<<UCSZ01 to R24
  STS     UCSR0C, R24           ; Set the value of R24 to UCSR0C
  RET                           ; Return

LCD_buffer:
  LDS     R28, UCSR0A           ; Load the value of UCSR0A to R28
  SBRS    R28, UDRE0            ; Skip if the value of UDRE0 is 0
  RJMP    LCD_buffer            ; Jump to LCD_buffer
  RET                           ; Return

ASCII_MSD:
  MOV     23, R16               ; Move the value of R16 to R23
  ANDI    R16, 0xF0             ; AND the value of R16 with 0xF0
  SWAP    R16                   ; Swap the value of R16
  SUBI    R16, -48              ; Subtract the value of -48 from R16
  MOV     R28, R16              ; Move the value of R16 to R28
  SUBI    R28, 58               ; Subtract the value of 58 from R28
  BRPL    A_F_D1                ; Branch if positive or zero to A_F_D1
lo1: 
  RET                           ; Return

ASCII_LSD:
  MOV     R16, R23              ; Move the value of R23 to R16
  ANDI    R16, 0x0F             ; AND the value of R16 with 0x0F
  SUBI    R16, -48              ; Subtract the value of -48 from R16
  MOV     R28, R16              ; Move the value of R16 to R28
  SUBI    R28, 58               ; Subtract the value of 58 from R28
  BRPL    A_F_D0                ; Branch if positive or zero to A_F_D0
loop2: 
  RET                           ; Return

A_F_D1:
  SUBI    R16, -7               ; Subtract the value of -7 from R16
  RJMP    lo1                   ; Jump to lo1
A_F_D0:
  SUBI    R16, -7               ; Subtract the value of -7 from R16
  RJMP    loop2                 ; Jump to loop2
  
delay_sec:
  LDI     R20, 255              ; Load the value of 255 to R20
loop4: 
  LDI     R21, 255              ; Load the value of 255 to R21
loop5: 
  LDI     R22, 82               ; Load the value of 82 to R22
loop6: 
  DEC     R22                   ; Decrement R22
  BRNE    loop6                 ; Branch if not equal to loop6
  DEC     R21                   ; Decrement R21
  BRNE    loop5                 ; Branch if not equal to loop5
  DEC     R20                   ; Decrement R20
  BRNE    loop4                 ; Branch if not equal to loop4
  RET                           ; Return