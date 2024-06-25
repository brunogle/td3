.global _irq_enable, _irq_disable

.section .text.kernel

/*
Subrutina _irq_enable

Habilita bit de interrupciones IRQ en el CPSR
*/
_irq_enable:
    DSB
    MRS R0, CPSR
    BIC R0, #0x80
    MSR CPSR, R0
    DSB
    ISB
    BX LR

/*
Subrutina _irq_disable

Deshabilita bit de interrupciones IRQ en el CPSR
*/
_irq_disable:
    DSB
    MRS R0, CPSR
    ORR R0, #0x80
    MSR CPSR, R0
    DSB
    ISB
    BX LR
