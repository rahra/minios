/*! \file main.S
 * This file contains the main() routine which is the first process started by
 * the kernel.
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

#include <avr/io.h>

.section .text

; main function
.global main
main:
   ldi   YL,lo8(led_proc)  ; Start led process (defined in ledproc.c) which
   ldi   YH,hi8(led_proc)  ; toggles the led.
   rcall start_proc

;   ldi   YL,lo8(sendp)     ; Start another process which send a single period
;   ldi   YH,hi8(sendp)     ; to the terminal (function defined below).
;   rcall start_proc

.Lmainloop:
   ldi   r26,lo8(buf)      ; Read line from terminal.
   ldi   r27,hi8(buf)
   rcall read
   
   ldi   r16,'\n'          ; output the string "\nOK\r\n"
   rcall send_byte
   ldi   r16,'O'
   rcall send_byte
   ldi   r16,'K'
   rcall send_byte
   ldi   r16,'\r'
   rcall send_byte
   ldi   r16,'\n'
   rcall send_byte

   rjmp  .Lmainloop        ; repeat endlessly


; Function to send a '.'.
sendp:
   ldi   r16,'.'           ; send '.'
   rcall send_byte
   ldi   r24,27            ; wait(27)
   ldi   r25,0
   rcall wait
   rjmp  sendp             ; endless loop


.section .data
buf:
.space 256

