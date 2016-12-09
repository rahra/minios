/*! \file led.S
 * This file contains functions to handle the led.
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "led.S"

#include <avr/io.h>


.section .text


; Function initializes the led port on the Arduino board.
.global init_ledport
init_ledport:
   ldi   r16,0x20                ; set bit 5 of port b to output
   out   _SFR_IO_ADDR(DDRB),r16
   ret


; Function to toggle led.
.global toggle_led
toggle_led:
   in    r16,_SFR_IO_ADDR(PORTB) ; read port b
   ldi   r17,0x20                ; toggle bit 5
   eor   r16,r17
   out   _SFR_IO_ADDR(PORTB),r16 ; output value to port b again
   ret

