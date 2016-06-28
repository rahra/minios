/*! Hier ist das Haupprogramm */


#include <avr/io.h>

.section .text


.global main
main:
   ldi   YL,lo8(led_proc)
   ldi   YH,hi8(led_proc)
   rcall start_proc

   ldi   YL,lo8(sendp)
   ldi   YH,hi8(sendp)
   rcall start_proc

.Lmainloop:
   ldi   r26,lo8(buf)
   ldi   r27,hi8(buf)
   rcall read
   
   ldi   r16,'\n'
   rcall send_byte
   ldi   r16,'O'
   rcall send_byte
   ldi   r16,'K'
   rcall send_byte
   ldi   r16,'\r'
   rcall send_byte
   ldi   r16,'\n'
   rcall send_byte

   rjmp  .Lmainloop


sendp:
   ldi   r16,'.'
   rcall send_byte
   ldi   r24,27
   ldi   r25,0
   rcall wait
   rjmp  sendp


.section .data
buf:
.space 256

