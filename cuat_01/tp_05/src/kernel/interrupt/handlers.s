.include "src/util/addr.s"


.global _reset_vector
.global UND_Handler
.global SVC_Handler
.global PREF_Handler
.global ABT_Handler
.global IRQ_Handler
.global FIQ_Handler

.include "src/util/addr.s"

/*
Esta sección contiene todos los handlers de execpciones e interrupciones
*/

.section .text_kernel,"ax"@progbits

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


