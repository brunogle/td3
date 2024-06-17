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
    
    PUSH {R0, R1, LR}
    LDR R0, =(TIMER0_ADDR + TIMER_MIS_OFFSET)
    LDR R1, [R0]
    

    TST R1, #0x1
    BNE scheduler_tick
    B other_irq


    scheduler_tick:

        //Clear de interrupcion del timer
        PUSH {R0, R1, LR}
        LDR R0, =(TIMER0_ADDR + TIMER_INTCLT_OFFSET) 
        STR R0, [R0]

        //Aumento el systick
        LDR R0, =systick_count
        LDR R1, [R0]
        ADD R1, R1, #1
        STR R1, [R0]

        POP {R0, R1, LR}
        
        BL _context_switch

    other_irq:

        POP {R0, R1, LR}
        MOVS PC, LR

/*
Fast Interrupt Request Handler
*/
_FIQ_Handler:
    SUB LR,LR,#4
    STMFD SP!,{R0-R3,LR}

    LDMFD SP!,{R0-R3,PC}^


