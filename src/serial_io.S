/*! \file serial_io.S
 * This file contains the code for the serial communication.
 *
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

#include <avr/io.h>


; baudrate 9600 at U2X0 = 1
#define BAUDCNT 207


.section .text


/*! Init serial communication port.
 */
.global init_serial
init_serial:
   ; set baudrate
   ldi   r16,hi8(BAUDCNT)
   sts   UBRR0H,r16
   ldi   r16,lo8(BAUDCNT)
   sts   UBRR0L,r16
   
   ldi   r16,2       ; set U2X0
   sts   UCSR0A,r16
   ldi   r16,6       ; 8N1
   sts   UCSR0C,r16
   ldi   r16,0x98    ; RXIE, RXEN, TXEN
   sts   UCSR0B,r16

   ; init helper variables
   clr   r16
   sts   rcomplete,r16
   sts   rcnt,r16

   ret


/*! This is the serial receive interrupt handler. It writes the bytes received
 * to the receive buffer rbuf. If a CR is received the variable rcomplete is
 * set to 1.
 */
.global rx_handler
rx_handler:
   push  r16
   in    r16,_SFR_IO_ADDR(SREG)
   push  r16

   ; read received character and send it back (echo)
   lds   r16,UDR0
   rcall send_byte

   ; check if it was a '\r'
   cpi   r16,'\r'
   breq  .Lrxend
   push  r17
   push  r28
   push  r29

   ; load base address of receive buffer to Y
   ldi   r28,lo8(rbuf)
   ldi   r29,hi8(rbuf)

   ; add counter rcnt to Y
   lds   r17,rcnt
   add   r28,r17
   clr   r17
   adc   r29,r17

   ; store received byte to buffer
   st    Y,r16

   ; increase byte counter
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
   ; set rcomplete flag to 1
   ldi   r16,1
   sts   rcomplete,r16
   rjmp  .Lrxexit  


/*! Send a byte directly (not interrupt driven) to the serial port.
 * @parameter r16 Character to send.
 */
.global  send_byte
send_byte:
   push  r17
   ; wait if transmitter is busy
.Lsendb:
   lds   r17,UCSR0A
   sbrs  r17,5
   rjmp  .Lsendb
   ; write byte to transmit buffer
   sts   UDR0,r16
   pop   r17
   ret


/*! This function implements the function read(). It copies data from the
 * kernel's receive buffer rbuf to the userland buffer. Finally it resets the
 * rcomplete flag to 0.
 * @param X Pointer to userland buffer.
 * @return r16 
 */
.global read
read:
   push  r17
   push  r28
   push  r29

   ; wait if received line is not complete
.Lrdstart:
   lds   r16,rcomplete
   tst   r16
   breq  .Lrdstart

   lds   r16,rcnt
   ; safetycheck r16 != 0
   tst   r16
   breq  .Lrdexit

   ; copy kernel data to userland buffer
   ldi   r28,lo8(rbuf)
   ldi   r29,hi8(rbuf)
.Lrloop:
   ld    r17,Y+
   st    X+,r17
   dec   r16
   brne  .Lrloop
   
.Lrdexit:
   ; return value (number of bytes) to r16
   lds   r16,rcnt
   ; set counter and flag to 0
   clr   r17
   sts   rcnt,r17
   sts   rcomplete,r17

   pop   r29
   pop   r28
   pop   r17
   ret
   

.section .data
; receive buffer
rbuf:
.space 256
; receive buffer byte counter
rcnt:
.space 1
; line complete flag ('\r' received)
rcomplete:
.space 1

