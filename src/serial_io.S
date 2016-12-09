/*! \file serial_io.S
 * This file contains the code for the serial communication.
 * It is an interrupt driven sender and receiver.
 *
 * @author Bernhard R. Fischer, 4096R/8E24F29D bf@abenteuerland.at
 */

.file "serial_io.S"

#include <avr/io.h>

; baud rate for 16MHz Arduino
; 207 = 9600, 103 = 19200, 16 = 115200
#define BAUDCOUNT 207


.section .text
.balign 2

.global init_serial
init_serial:
   push  r16
   
   ldi   r16,hi8(BAUDCOUNT)
   sts   UBRR0H,r16
   ldi   r16,lo8(BAUDCOUNT)
   sts   UBRR0L,r16
   ldi   r16,0x02                ; mode U2X (double baud clock)
   sts   UCSR0A,r16
   ldi   r16,0x18 | _BV(RXCIE0)  ; RXCIE, RXEN, TXEN
   sts   UCSR0B,r16
   ldi   r16,0x06    ; 8N1
   sts   UCSR0C,r16

   rcall sys_read_flush
   clr   r16
   sts   kbuf_output_end,r16
   sts   kbuf_output_pos,r16

   pop   r16
   ret


/*! Serial receiver interrupt handler. */
.global serial_rx_handler
serial_rx_handler:
   push  r16
   in    r16,_SFR_IO_ADDR(SREG)

   push  r16
   push  r17
   push  r18
   push  r28
   push  r29

   lds   r16,UDR0       ; read data from input register
   cpi   r16,8          ; backspace?
   breq  .Lhandlebs
   cpi   r16,'\r'
   brne  .Lsersave
   ldi   r16,'\n'
   sts   kbuf_input_ready,r16

.Lsersave:
   rcall sys_send             ; send character back
   ldi   YL,lo8(kbuf_input)  ; buffer address to Y
   ldi   YH,hi8(kbuf_input)
   lds   r17,kbuf_input_pos   ; get byte counter from RAM
   clr   r18                  ; Y += r17 (16 bit)
   add   r28,r17
   adc   r29,r18
   st    Y,r16                ; copy character to buffer
   inc   r17                  ; increase character counter
   sts   kbuf_input_pos,r17   ; write counter back to RAM

.Lrx_int_exit:
   pop   r29
   pop   r28
   pop   r18
   pop   r17
   pop   r16

   out   _SFR_IO_ADDR(SREG),r16
   pop   r16
   reti

.Lhandlebs:
   lds   r17,kbuf_input_pos
   tst   r17
   breq  .Lrx_int_exit

   ldi   r28,lo8(dummy)
   ldi   r29,hi8(dummy)
   ldi   r16,3
   rcall sys_pwrite

   dec   r17
   sts   kbuf_input_pos,r17
   rjmp  .Lrx_int_exit
   

#ifdef WITH_SYSCALL
.global  send
send:
   push  r24
   ldi   r24,SYS_SEND
   rcall syscall
   pop   r24
   ret
#endif


#if 0
/*! Send a byte directly (not interrupt driven) to the serial port.
 * @parameter r16 Character to send.
 */
.global  send_direct
send_direct:
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
#endif


; send a single byte to serial buffer
; @param r16 byte to send
.global  sys_send
sys_send:
   push  r28
   push  r29
   push  r16
   in    r28,_SFR_IO_ADDR(SPL)
   in    r29,_SFR_IO_ADDR(SPH)
   ldi   r16,1
   adiw  r28,1
   rcall sys_write
   pop   r16
   pop   r29
   pop   r28
   ret

/*   push  r17
.Lsendwait:
   lds   r17,UCSR0A
   sbrs  r17,5
   rjmp  .Lsendwait
   sts   UDR0,r16
   pop   r17
   ret*/


#ifdef WITH_SYSCALL
.global  read
read:
   push  r24
   ldi   r24,SYS_READ
   rcall syscall
   pop   r24
   ret
#endif


; read a line from input buffer
; FIXME: there's no paramter for buffer length
; @param Y start address of destination buffer buffer should be 256 bytes long)
; @return r24 number of bytes copied
.global  sys_read
sys_read:
   push  r16
   push  r17
   push  r30
   push  r31

.Lrdtest:
   lds   r16,UCSR0B
   andi  r16,~_BV(RXCIE0)     ; disable receiver interrupt
   sts   UCSR0B,r16

;.Lrdtest:
   lds   r16,kbuf_input_ready
   tst   r16
   breq  .Lrdwait
   
   ; Daten vorhanden
   ;cli   ; workaround
   ldi   r30,lo8(kbuf_input)
   ldi   r31,hi8(kbuf_input)
   lds   r16,kbuf_input_pos   ; loop counter
   mov   r24,r16
.Lrdloop:
   ld    r17,Z+               ; copy bytes
   st    Y+,r17
   dec   r16
   brne  .Lrdloop
   
   sts   kbuf_input_pos,r16
   sts   kbuf_input_ready,r16
   ;sei   ; workaround

   lds   r16,UCSR0B           ; enable receiver interrupt
   ori   r16,_BV(RXCIE0)
   sts   UCSR0B,r16

   pop   r31
   pop   r30
   pop   r17
   pop   r16
   ret

.Lrdwait:                     ; no data available
   lds   r16,UCSR0B           ; enable receiver interrupt
   ori   r16,_BV(RXCIE0)
   sts   UCSR0B,r16
   ;sleep                     ; FIXME: we should pass control to scheduler here
   rjmp  .Lrdtest


.global  sys_read_flush
sys_read_flush:
   push  r16
   clr   r16
   sts   kbuf_input_ready,r16 ; set ready variable to 0
   sts   kbuf_input_pos,r16 
   pop   r16
   ret


.global  serial_tx_handler
serial_tx_handler:
   push  r0
   in    r0,_SFR_IO_ADDR(SREG)
   push  r16
   push  r17

   lds   r16,kbuf_output_end
   lds   r17,kbuf_output_pos
   sub   r16,r17
   brne  .Lstx_send_byte
   lds   r17,UCSR0B           ; switch off interrupt
   andi  r17,~_BV(UDRIE0)
   sts   UCSR0B,r17
   rjmp  .Lstx_exit

.Lstx_send_byte:
   push  r28
   push  r29
   ldi   r28,lo8(kbuf_output) ; load send buffer address to Y
   ldi   r29,hi8(kbuf_output)
   add   r28,r17              ; add send_pos to Y
   clr   r16
   adc   r29,r16
   ld    r16,Y                ; load byte from send buffer
   sts   UDR0,r16             ; write to serial register
   inc   r17
   sts   kbuf_output_pos,r17  ; store new send_pos to RAM
   pop   r29
   pop   r28

.Lstx_exit:
   pop   r17
   pop   r16
   out   _SFR_IO_ADDR(SREG),r0
   pop   r0
   reti


#ifdef WITH_SYSCALL
.global  write
write:
   rcall sys_lock
   push  r24
   ldi   r24,SYS_WRITE
   rcall syscall
   pop   r24
   rcall sys_unlock
   ret
#endif


.global  sys_write
; write string to serial port output buffer
; @param src Source SRAM address in Y (modified)
; @param cnt Number of bytes in r16 (modified)
sys_write:
   tst   r16
   brne  .Lwrite
   ret

.Lwrite:
   push  r16
   push  r17
   push  r18
   push  r30
   push  r31

.Lwrite_test_buf:
   lds   r17,UCSR0B     ; disable USART Data Register Empty Interrupt
   andi  r17,~_BV(UDRIE0)
   sts   UCSR0B,r17

   lds   r17,kbuf_output_end
   lds   r18,kbuf_output_pos
   sub   r18,r17        ; calculate number of free bytes in buffer
   breq  .Lwrite_start  ; if 0 -> assume 256
   cp    r16,r18        ; test if there's enough free. There must be at least 1 byte more free than in r16
   brsh  .Lwrite_block  ; block if r18 <= r16

.Lwrite_start:
   ldi   r30,lo8(kbuf_output)  ; load send buffer address to Z
   ldi   r31,hi8(kbuf_output)
   add   r30,r17        ; increase Z by send_buf_end
   ldi   r18,0
   adc   r31,r18

.Lwrite_copy:
   ld    r18,Y+         ; load byte from source buffer
   st    Z+,r18         ; store byte to destination buffer (send buffer)

   inc   r17            ; increase send_buf_end
   brne  .Lwrite_dec
   rcall .Lwrite_ld_baddr ; buffer wraps
.Lwrite_dec:
   dec   r16
   brne  .Lwrite_copy

   sts   kbuf_output_end,r17   ; store new end address of new buffer
                        
   lds   r17,UCSR0B     ; enable USART Data Register Empty Interrupt
   ori   r17,_BV(UDRIE0)
   sts   UCSR0B,r17

   pop   r31
   pop   r30
   pop   r18
   pop   r17
   pop   r16
   ret

.Lwrite_ld_baddr:
   ldi   r30,lo8(kbuf_output)  ; load send buffer address to Z
   ldi   r31,hi8(kbuf_output)
   ret

.Lwrite_block:
   lds   r17,UCSR0B           ; enable interrupt
   ori   r17,_BV(UDRIE0)
   sts   UCSR0B,r17
   ;sleep
   rjmp  .Lwrite_test_buf


#ifdef WITH_SYSCALL
.global  pwrite
pwrite:
   push  r24
   ldi   r24,SYS_PWRITE
   rcall syscall
   pop   r24
   ret
#endif


.global sys_pwrite
; write string to serial port output buffer
; @param src Source PROGMEM address in Y (modified)
; @param cnt Number of bytes in r16 (modified)
sys_pwrite:
   tst   r16                     ; safety check r16 != 0
   brne  .Lpwrite
   ret

.Lpwrite:
   push  ZL
   push  ZH
   push  r17

   movw  ZL,YL
   mov   r17,r16        ; copy one byte after the other to r16
.Lpwloop:
   lpm   r16,Z+
   rcall sys_send       ; and call sys_send()
   dec   r17
   brne  .Lpwloop
   
   pop   r17
   pop   ZH
   pop   ZL
   ret


dummy:
.byte 8,' ',8
 
.section .data
; data buffer for incoming bytes
kbuf_input:
.space   256
; number of bytes in the input buffer
kbuf_input_pos:
.space   1
; variable != 0 if '\n' was read, otherwise 0
kbuf_input_ready:
.space   1
; output buffer
kbuf_output:
.space 256
kbuf_output_end:      ; points to the 1st free byte behind the data to send
.space   1
kbuf_output_pos:      ; points to the 1st byte of data to send
.space   1

