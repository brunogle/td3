.global UND_Handler
.global SVC_Handler
.global PREF_Handler
.global ABT_Handler
.global IRQ_Handler
.global FIQ_Handler

.equ USR_MODE, 0x10    /* USER       - Encoding segun ARM B1.3.1 (pag. B1-1139): 10000 - Bits 4:0 del CPSR */
.equ FIQ_MODE, 0x11    /* FIQ        - Encoding segun ARM B1.3.1 (pag. B1-1139): 10001 - Bits 4:0 del CPSR */
.equ IRQ_MODE, 0x12    /* IRQ        - Encoding segun ARM B1.3.1 (pag. B1-1139): 10010 - Bits 4:0 del CPSR */
.equ SVC_MODE, 0x13    /* Supervisor - Encoding segun ARM B1.3.1 (pag. B1-1139): 10011 - Bits 4:0 del CPSR */
.equ ABT_MODE, 0x17    /* Abort      - Encoding segun ARM B1.3.1 (pag. B1-1139): 10111 - Bits 4:0 del CPSR */
.equ UND_MODE, 0x1B    /* Undefined  - Encoding segun ARM B1.3.1 (pag. B1-1139): 11011 - Bits 4:0 del CPSR */
.equ SYS_MODE, 0x1F    /* System     - Encoding segun ARM B1.3.1 (pag. B1-1139): 11111 - Bits 4:0 del CPSR */
.equ I_BIT,    0x80    /* Mask bit I - Encoding segun ARM B1.3.3 (pag. B1-1149) - Bit 7 del CPSR */
.equ F_BIT,    0x40    /* Mask bit F - Encoding segun ARM B1.3.3 (pag. B1-1149) - Bit 6 del CPSR */


.section .handlers,"ax"@progbits

_reset_vector:
   @ ldr PC,=_start
   B _start

UND_Handler:  
    SRSFD   SP!, #UND_MODE
    LDR R10,=#0x0100
    RFEFD   SP!  

SVC_Handler:
    SRSFD   SP!, #SVC_MODE
    LDR R10,=#0x0200
    RFEFD   SP!

PREF_Handler:
    SRSFD   SP!, #ABT_MODE
    LDR R10,=#0x0300
    RFEFD   SP!

ABT_Handler:
    SRSFD   SP!, #ABT_MODE
    LDR R10,=#0x0400
    RFEFD   SP!

IRQ_Handler:
    SRSFD   SP!, #IRQ_MODE
    LDR R10,=#0x0500
    RFEFD   SP!

FIQ_Handler:
    SRSFD   SP!, #FIQ_MODE
    LDR R10,=#0x0600
    RFEFD   SP!



.section .isr_table,"ax"@progbits

_table_start:
    LDR PC, addr__reset_vector
    LDR PC, addr_UND_Handler
    LDR PC, addr_SVC_Handler
    LDR PC, addr_PREF_Handler
    LDR PC, addr_ABT_Handler
    LDR PC, addr_start
    LDR PC, addr_IRQ_Handler
    LDR PC, addr_FIQ_Handler


addr__reset_vector:  .word _reset_vector
addr_UND_Handler  :  .word UND_Handler  
addr_SVC_Handler  :  .word SVC_Handler  
addr_PREF_Handler :  .word PREF_Handler 
addr_ABT_Handler  :  .word ABT_Handler  
addr_start        :  .word _start        
addr_IRQ_Handler  :  .word IRQ_Handler  
addr_FIQ_Handler  :  .word FIQ_Handler  
