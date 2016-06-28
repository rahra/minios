/*! Hier sind alle Timer-Funktionen.... */

.include "macro.i"

#include <avr/io.h>

#define TIMEROVLCNT 30

.section .text

.global init_timer
init_timer:
   clr   r16                     ; set timer normal mode
   out   _SFR_IO_ADDR(TCCR0A),r16
   ldi   r16,0x05                ; set clock divider 1024
   out   _SFR_IO_ADDR(TCCR0B),r16
   clr   r16                     ; counter register auf 0 (=256)
   out   _SFR_IO_ADDR(TCNT0),r16

   ldi   r16,1                   ; timer interrupt enable
   sts   TIMSK0,r16

   ldi   XL,lo8(uptime)          ; init uptime to 0
   ldi   XH,hi8(uptime)

   clr   r16
   st    X+,r16
   st    X+,r16
   st    X+,r16
   st    X+,r16

   ret

.global t0_handler
t0_handler:
   ; save full context to (current) stack
   pushm 0,31
   in    r16,_SFR_IO_ADDR(SREG)
   push  r16

   rcall t0_count

   ; copy SP to Y
   in    YL,_SFR_IO_ADDR(SPL)
   in    YH,_SFR_IO_ADDR(SPH)

   ; do context switch
   rcall context_switch

   ; copy new stack address in Y to SP
   out   _SFR_IO_ADDR(SPL),YL
   out   _SFR_IO_ADDR(SPH),YH

   ; restore full context
   pop   r16
   out   _SFR_IO_ADDR(SREG),r16
   popm  0,31
   reti

t0_count:
   ldi   XL,lo8(uptime)
   ldi   XH,hi8(uptime)

   ld    r28,X+
   ld    r29,X+
   ld    r30,X+
   ld    r31,X+

   clr   r16
   adiw  r28,1
   adc   r30,r16
   adc   r31,r16
   
   st    -X,r31
   st    -X,r30
   st    -X,r29
   st    -X,r28

   ret


; long get_uptime(void)
; return global uptime
.global get_uptime
get_uptime:
   ldi   XL,lo8(uptime)
   ldi   XH,hi8(uptime)

   cli
   ld    r22,X+
   ld    r23,X+
   ld    r24,X+
   ld    r25,X+
   sei

   ret

.section .data
; 32 bit uptime counter
uptime:
.space 4



