/*! \file init.S
 * System initialization.
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "init.S"

#include <avr/io.h>


.section .vectors

; reset vector
.org 0
   rjmp  __ctors_start

; timer 0 overflow vector
.org 0x40
   rjmp  t0_handler

; serial input buffer vector
.org 0x48
   rjmp  serial_rx_handler

.org 0x4c
   rjmp  serial_tx_handler


; "ConstrucTORS"
;__ctors_start:
.section .ctors
   ldi   r16,0                   ; clear system status register
   out   _SFR_IO_ADDR(SREG),r16
   ldi   r16,lo8(RAMEND)         ; init stack
   out   _SFR_IO_ADDR(SPL),r16
   ldi   r16,hi8(RAMEND)
   out   _SFR_IO_ADDR(SPH),r16

   rcall init_procs              ; call OS initialization routines
   rcall init_timer
   rcall init_ledport
   rcall init_serial

   ldi   r16,lo8(main)           ; start first process (main)
   ldi   r17,hi8(main)
   lsr   r17
   ror   r16
   push  r16
   push  r17
   
   reti

