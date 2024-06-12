/*
Este archivo contiene los handlers para las interrupciones y
exepciones.
*/

.global _reset_vector
.global _UND_Handler
.global _SVC_Handler
.global _PREF_Handler
.global _ABT_Handler
.global _IRQ_Handler
.global _FIQ_Handler

.include "src/cpu_defines.s"

/*
Esta sección contiene todos los handlers de execpciones e interrupciones
*/

.section .text_kernel,"ax"@progbits

/*
Reset Vector
*/
_reset_vector:
   B _start

/*
Undefined Instruction handler
*/
_UND_Handler:
    STMFD SP!,{R0-R3,LR}
    
    LDR R10, =0x00494E56 //Escribe "UND" en R10

    LDMFD SP!,{R0-R3,PC}^

/*
Software Interrupt Handler
*/
_SVC_Handler:
    STMFD SP!,{R0-R3,LR}

    LDR R10, =0x00435653

    LDMFD SP!,{R0-R3,PC}^

/*
Prefetch Abort Handler
*/
_PREF_Handler:
    SUB LR,LR,#4
    STMFD SP!,{R0-R3,LR}

    LDR R10, =0x004D454D

    LDMFD SP!,{R0-R3,PC}^


/*
Data Abort Handler
*/
_ABT_Handler:
    SUB LR,LR,#8
    STMFD SP!,{R0-R3,LR}

    LDR R10, =0x004D454D

    LDMFD SP!,{R0-R3,PC}^

/*
Interrupt Request Handler
*/
_IRQ_Handler:
    SUB LR,LR,#4
    STMFD SP!,{R0-R3,LR}

    //Clear de interrupcion del timer
    LDR R0, =(TIMER0_ADDR + TIMER_INTCLT_OFFSET) 
	STR R0, [R0]

    //Como pide la consigna, aumento R10 en 1
    ADD R10, R10, #1

    LDMFD SP!,{R0-R3,PC}^

/*
Fast Interrupt Request Handler
*/
_FIQ_Handler:
    SUB LR,LR,#4
    STMFD SP!,{R0-R3,LR}

    LDMFD SP!,{R0-R3,PC}^


