
/*
Este archivo solamente contiene la tabla de ISR.
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
addr_UND_Handler  :  .word _UND_Handler  
addr_SVC_Handler  :  .word _SVC_Handler  
addr_PREF_Handler :  .word _PREF_Handler 
addr_ABT_Handler  :  .word _ABT_Handler  
addr_start        :  .word _start        
addr_IRQ_Handler  :  .word _IRQ_Handler  
addr_FIQ_Handler  :  .word _FIQ_Handler  

