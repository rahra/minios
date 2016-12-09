/*! \file main.S
 * This file contains the main() routine which is the first process started by
 * the kernel.
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "main.S"

#include <avr/io.h>

#define SEND_PROMPT

.section .text

; Main function. It is finally called in the init routing of the kernel (in
; init.S). It starts additional processes and then in a loop reads from
; the serial port and outputs the string "\nOK\r\n" to the serial port.
.global main
main:
   ldi   YL,lo8(led_proc)  ; Start led process (defined in ledproc.c) which
   ldi   YH,hi8(led_proc)  ; toggles the led.
   rcall start_proc

;   ldi   YL,lo8(sendp)     ; Start another process which send a single period
;   ldi   YH,hi8(sendp)     ; to the terminal (function defined below).
;   rcall start_proc

.Lmainloop:
#ifdef SEND_PROMPT
   ldi   YL,lo8(.Lstr_arduino)
   ldi   YH,hi8(.Lstr_arduino)
   ldi   r16,.Lstr_arduino_len
   rcall sys_pwrite
#endif

   rcall sys_read_flush
   ldi   r26,lo8(buf)      ; Read line from terminal into the buffer buf.
   ldi   r27,hi8(buf)
   rcall sys_read
   
   ldi   YL,lo8(.Lstr_ok)  ; send "ok" string
   ldi   YH,hi8(.Lstr_ok)
   ldi   r16,.Lstr_ok_len
   rcall sys_pwrite

   rjmp  .Lmainloop        ; Repeat endlessly.


; Function to send a '.'.
sendp:
   ldi   r16,'.'           ; send '.'
   rcall sys_send
   ldi   r24,27            ; wait(27)
   ldi   r25,0
   rcall wait
   rjmp  sendp             ; endless loop

.Lstr_ok:
.ascii "\rOK\r\n"
.set .Lstr_ok_len, . - .Lstr_ok
.Lstr_arduino:
.ascii "Arduino> "
.set .Lstr_arduino_len, . - .Lstr_arduino

.balign 2


.section .data

; Data buffer used for serial input.
buf:
.space 256


