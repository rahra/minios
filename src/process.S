/*! \file process.S
 * This file contains the routines for the process management.
 *
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "process.S"

#include <avr/io.h>

; maximum number of processes
#define MAX_PROCS 5
; number of bytes used per process in the process list
#define PROC_LIST_ENTRY 2
; process stack size
#define STACK_SIZE 64

.section .text

; Initialize default values at kernel startup.
.global init_procs
init_procs:
   clr   r16               ; Set the current PID to 0.
   sts   current_proc,r16
   ldi   r16,1             ; Set the number of processes to 1.
   sts   num_proc,r16
   ret


; Function saves stack pointer and returns new stack pointer
; @param stack pointer to save in Y
; @return new stack pointer returned in Y

.global context_switch
context_switch:
   lds   r16,current_proc
   rcall proc_list_address

   ; save current SP (Y) to proc_list
   st    Z+,YL
   st    Z,YH

   ; determine next process to schedule
   rcall get_next_proc
   sts   current_proc,r16

   ; calculate process list address of new process
   rcall proc_list_address
   ; ...and store its stack address to Y
   ld    YL,Z+
   ld    YH,Z

   ret


; Calculate address of proc_list entry
; @param r16 number of process
; @return Z contains address of proc_list entry
proc_list_address:
   push  r17

   ; calculate process list offset:
   ; multiply process number with size per entry
   ldi   r17,PROC_LIST_ENTRY
   mul   r17,r16

   ; get start address of process list
   ldi   ZL,lo8(proc_list)
   ldi   ZH,hi8(proc_list)
   ; and add offset
   add   ZL,r0
   adc   ZH,r1
   
   pop   r17
   ret


; get number of next process
; This actually is the (most simple round robin) scheduler ;)
; @param r16 current process
; @return r16 number of next process
get_next_proc:
   ; increase current PID
   inc   r16
   push  r17
   ; and start at the first process if the last one is reached
   lds   r17,num_proc
   cp    r16,r17
   brne  .Lgnpexit
   clr   r16
.Lgnpexit:
   pop   r17
   ret


; Start a new process
; @param Y Start address of new process
.global start_proc
start_proc:
   push  r16
   push  XL
   push  XH
   push  YL
   push  YH
   push  ZL
   push  ZH

   movw  r26,r28

   ; disable all interrupts
   cli

   ; get new PID and calculate stack (top) address
   lds   r16,num_proc
   rcall stack_address

   lsr   XH    ; divide process entry address by 2
   ror   XL    ; (because AVR prog addresses are word not byte addresses)

   st    Y,XL  ; save entry point to the stack of the new process
   st    -Y,XH

   sbiw  YL,32 ; subtract 32 from Y (stack) which is the register space
               ; of the context switcher

   clr   r16   ; store 0 to Y (stack) which is the SREG
   st    -Y,r16

   sbiw  YL,1

   ; store final stack address to the process list
   lds   r16,num_proc
   rcall proc_list_address

   st    Z+,YL   ; store new stack pointer to proc_list
   st    Z,YH

   ; increase total number of processes
   inc   r16
   sts   num_proc,r16

   ; enable interrupts again
   sei

   pop   ZH
   pop   ZL
   pop   YH
   pop   YL
   pop   XH
   pop   XL
   pop   r16

   ret



; Calculate address of stack in memory
; @param r16 Number of process (PID)
; @return Y address of stack
stack_address:
   mov   r0,r16
   ldi   r16,STACK_SIZE
   mul   r16,r0

   ldi   YL,lo8(RAMEND)
   ldi   YH,hi8(RAMEND)
   sub   YL,r0
   sbc   YH,r1

   ret
  

.global sys_sleep
sys_sleep:
   sleep
   ret


.section .data
; currently active process
current_proc:
.space 1
; total number of "running" processes
num_proc:
.space 1
; process list
proc_list:
.space MAX_PROCS * PROC_LIST_ENTRY

