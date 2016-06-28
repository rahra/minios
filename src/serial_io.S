#include <avr/io.h>


; Baudrate auf 9600 bei U2X0 = 1
#define BAUDCNT 207



.section .text


.global init_serial
init_serial:
   ldi   r16,hi8(BAUDCNT)
   sts   UBRR0H,r16
   ldi   r16,lo8(BAUDCNT)
   sts   UBRR0L,r16
   
   ldi   r16,2       ; U2X0 setzem
   sts   UCSR0A,r16
   ldi   r16,6       ; 8N1
   sts   UCSR0C,r16
   ldi   r16,0x98    ; RXIE, RXEN, TXEN
   sts   UCSR0B,r16

   clr   r16
   sts   rcomplete,r16
   sts   rcnt,r16

   ret


.global rx_handler
rx_handler:
   push  r16
   in    r16,_SFR_IO_ADDR(SREG)
   push  r16

   lds   r16,UDR0
   rcall send_byte

   ; Zeilenende (Return) überprüfen
   cpi   r16,'\r'
   breq  .Lrxend
   push  r17
   push  r28
   push  r29

   ; Basisadress von Puffer in Y
   ldi   r28,lo8(rbuf)
   ldi   r29,hi8(rbuf)

   ; Counter rcnt zu Y dazuaddieren
   lds   r17,rcnt
   add   r28,r17
   clr   r17
   adc   r29,r17

   ; Gelesenes Byte in Puffer speichern
   st    Y,r16

   ; Counter erhöhen
   lds   r17,rcnt
   inc   r17
   sts   rcnt,r17

   pop   r29
   pop   r28
   pop   r17

.Lrxexit:
   pop   r16
   out   _SFR_IO_ADDR(SREG),r16
   pop   r16
   reti

.Lrxend:
   ; Flag auf 1 setzen
   ldi   r16,1
   sts   rcomplete,r16
   rjmp  .Lrxexit  


; Sendet direkt das Byte aus r16
.global  send_byte
send_byte:
   push  r17
.Lsendb:
   lds   r17,UCSR0A
   sbrs  r17,5
   rjmp  .Lsendb
   sts   UDR0,r16
   pop   r17
   ret


; funktion read liest aus dem Kernel Read-Buffer (rbuf) in einen
; definierten Speicherbereich, der im Register X uebergeben wird
.global read
read:
   push  r17
   push  r28
   push  r29

.Lrdstart:
   lds   r16,rcomplete
   tst   r16
   breq  .Lrdstart

   lds   r16,rcnt
   ; safetycheck r16 != 0
   tst   r16
   breq  .Lrdexit

   ldi   r28,lo8(rbuf)
   ldi   r29,hi8(rbuf)
.Lrloop:
   ld    r17,Y+
   st    X+,r17
   dec   r16
   brne  .Lrloop
   
.Lrdexit:
   ; Rückgabewert (Anzahl Bytes) in r16
   lds   r16,rcnt
   ; Counter und Flag auf 0 setzen
   clr   r17
   sts   rcnt,r17
   sts   rcomplete,r17

   pop   r29
   pop   r28
   pop   r17
   ret
   

.section .data
rbuf:
.space 256
rcnt:
.space 1
rcomplete:
.space 1

