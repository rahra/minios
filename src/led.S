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
   ldi   r18,0x20                ; set bit 5 of port b to output
   out   _SFR_IO_ADDR(DDRB),r18
   ret


; Function to toggle led.
.global toggle_led
toggle_led:
   in    r18,_SFR_IO_ADDR(PORTB) ; read port b
   ldi   r19,0x20                ; toggle bit 5
   eor   r18,r19
   out   _SFR_IO_ADDR(PORTB),r18 ; output value to port b again
   ret

