.global _irq_enable, _irq_disable

.section .text_kernel,"ax"@progbits

/*
Habilita interrupciones
*/
.align 4  // Alineado a 4 Bytes
_irq_enable:
    DSB
    MRS R0, CPSR
    BIC R0, #0x80
    MSR CPSR, R0
    DSB
    ISB
    BX LR

/*
Deshabilita interrupciones
*/
.align 4  // Alineado a 4 Bytes
_irq_disable:
    DSB
    MRS R0, CPSR
    ORR R0, #0x80
    MSR CPSR, R0
    DSB
    ISB
    BX LR
