/*! \file timer.S
 * This file contains all timer related functions. This is an uptime counter
 * and the context switching for the multi-tasking.
 *
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.include "macro.i"

#include <avr/io.h>

.section .text


/*! Initialize the timer 0 to simple overflow mode with a clock divider of
 * 1024. Thus, the timer interrupt is triggered all 16.384 ms on an 16 MHz
 * Arduino board (1 / 16000000 * 1024 * 256 = 0.016384 s). This is the chosen
 * time slice for this multi-tasking operating system.
 */
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


/*! This is the interrupt handler for the timer 0 interrupt. It invokes the
 * context switch and it increases the uptime counter.
 */
.global t0_handler
t0_handler:
   ; save full context to (current) stack
   pushm 0,31
   in    r16,_SFR_IO_ADDR(SREG)
   push  r16

   ; call uptime counter
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


/*! This function increases to system uptime by 1.
 */
t0_count:
   ; load address of uptime variable to X
   ldi   XL,lo8(uptime)
   ldi   XH,hi8(uptime)

   ; get current uptime from memory
   ld    r28,X+
   ld    r29,X+
   ld    r30,X+
   ld    r31,X+

   ; increase by 1
   clr   r16
   adiw  r28,1
   adc   r30,r16
   adc   r31,r16

   ; write uptime back to memory
   st    -X,r31
   st    -X,r30
   st    -X,r29
   st    -X,r28

   ret


/*! This function returns the current uptime.
 *  @prototype long get_uptime(void)
 *  @return 32 bit uptime in r22-r25.
 */
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

