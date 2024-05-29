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
    STMFD SP!,{R0-R3,LR}
    
    LDR R10, =0x00494E56

    LDMFD SP!,{R0-R3,PC}^
SVC_Handler:
    STMFD SP!,{R0-R3,LR}

    LDR R10, =0x00435653

    LDMFD SP!,{R0-R3,PC}^

PREF_Handler:
    SUB LR,LR,#4
    STMFD SP!,{R0-R3,LR}

    LDR R10, =0x004D454D

    LDMFD SP!,{R0-R3,PC}^

ABT_Handler:
    SUB LR,LR,#8
    STMFD SP!,{R0-R3,LR}

    LDR R10, =0x004D454D

    LDMFD SP!,{R0-R3,PC}^

IRQ_Handler:
    SUB LR,LR,#4
    STMFD SP!,{R0-R3,LR}

    //Clear de interrupcion del timer
    LDR R0, =(TIMER0_ADDR + TIMER_INTCLT_OFFSET) 
	STR R0, [R0]

    //Como pide la consigna, aumento R10 en 1
    ADD R10, R10, #1

    LDMFD SP!,{R0-R3,PC}^

FIQ_Handler:
    SUB LR,LR,#4
    STMFD SP!,{R0-R3,LR}

    LDMFD SP!,{R0-R3,PC}^


