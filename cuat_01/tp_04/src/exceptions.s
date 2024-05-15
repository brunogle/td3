.include "src/addr.s"

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


/*
Esta sección contiene todos los handlers de execpciones e interrupciones
*/

.section .handlers,"ax"@progbits

_reset_vector:
   @ ldr PC,=_start
   B _start

UND_Handler:  
    SRSFD   SP!, #UND_MODE
    LDR R10, =0x00494E56
    RFEFD   SP!  

SVC_Handler:
    SRSFD   SP!, #SVC_MODE
    LDR R10, =0x00435653
    RFEFD   SP!

PREF_Handler:
    SRSFD   SP!, #ABT_MODE
    LDR R10, =0x004D454D
    RFEFD   SP!

ABT_Handler:
    SRSFD   SP!, #ABT_MODE
    LDR R10, =0x004D454D
    RFEFD   SP!

IRQ_Handler:
    SRSFD   SP!, #IRQ_MODE

    //Clear de interrupcion del timer
    LDR R0, =(TIMER0_ADDR + TIMER_INTCLT_OFFSET) 
	STR R0, [R0]

    //Como pide la consigna, aumento R10 en 1
    ADD R10, R10, #1

    RFEFD   SP!

FIQ_Handler:
    SRSFD   SP!, #FIQ_MODE
    RFEFD   SP!




/*
Esta tabla se encuentra un lugar de memoria especial distinto a el resto del programa
*/
.section .isr_table,"ax"@progbits


// Los flags _EXCEPTIONS_ENABLED, _IRQ_ENABLED y _FIQ_ENABLED pueden ser definidos externamente
// ensamblando con --defsym. El makefile los setea si el programador quiere deshabilitar execpiones
// EL ORDEN ES CRITICO PARA EL FUNCIONAMIENTO
_table_start:
    // Reset
    LDR PC, addr__reset_vector 

    // UNDEF
.if _EXCEPTIONS_ENABLED != 0
    LDR PC, addr_UND_Handler
.else
    SUBS  PC, LR, #0
.endif

    // SWI
.if _SWI_ENABLED != 0
    LDR PC, addr_SVC_Handler
.else
    SUBS  PC, LR, #0
.endif

    // PABT
.if _EXCEPTIONS_ENABLED != 0
    LDR PC, addr_PREF_Handler
.else
    SUBS  PC, LR, #4
.endif

    // DABT
.if _EXCEPTIONS_ENABLED != 0
    LDR PC, addr_ABT_Handler 
.else
    SUBS  PC, LR, #8
.endif

    // Reserved
    LDR PC, addr_start

    // IRQ
.if _IRQ_ENABLED != 0
    LDR PC, addr_IRQ_Handler
.else
    SUBS  PC, LR, #4
.endif

    // FIQ
.if _FIQ_ENABLED != 0
    LDR PC, addr_FIQ_Handler
.else
    SUBS PC, LR, #4
.endif

addr__reset_vector:  .word _reset_vector
addr_UND_Handler  :  .word UND_Handler  
addr_SVC_Handler  :  .word SVC_Handler  
addr_PREF_Handler :  .word PREF_Handler 
addr_ABT_Handler  :  .word ABT_Handler  
addr_start        :  .word _start        
addr_IRQ_Handler  :  .word IRQ_Handler  
addr_FIQ_Handler  :  .word FIQ_Handler  

