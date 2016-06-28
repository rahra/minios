/* hier sind alle led funktion... */

#include <avr/io.h>


.section .text


.global init_ledport
init_ledport:
   ldi   r16,0x20
   out   _SFR_IO_ADDR(DDRB),r16
   ret


.global toggle_led
toggle_led:
   in    r16,_SFR_IO_ADDR(PORTB)
   ldi   r17,0x20
   eor   r16,r17
   out   _SFR_IO_ADDR(PORTB),r16
   ret

