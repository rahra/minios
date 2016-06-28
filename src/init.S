/*! \file init.S
 * System initialisierung.
 */

#include <avr/io.h>


.section .vectors

.org 0
   rjmp  __ctors_start

.org 0x40
   rjmp  t0_handler

.org 0x48
   rjmp  rx_handler


; hier kommen die "ConstrucTORS"
;__ctors_start:
.section .ctors
   ldi   r16,0
   out   _SFR_IO_ADDR(SREG),r16
   ldi   r16,lo8(RAMEND)
   out   _SFR_IO_ADDR(SPL),r16
   ldi   r16,hi8(RAMEND)
   out   _SFR_IO_ADDR(SPH),r16

   rcall init_procs
   rcall init_timer
   rcall init_ledport
   rcall init_serial

   ldi   r16,lo8(main)
   ldi   r17,hi8(main)
   lsr   r17
   ror   r16
   push  r16
   push  r17
   
   reti


