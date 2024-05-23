.global _mmu_write_ttbr0, _mmu_read_ttbr0
.global _mmu_write_dacr, _mmu_read_dacr
.global _mmu_write_cr, _mmu_read_cr
.global _mmu_enable, _mmu_disable

.section .kernel,"ax"@progbits

_mmu_write_ttbr0:
    MCR P15, 0, R0, C2, C0, 0
    BX LR

_mmu_read_ttbr0:
    MRC P15, 0, R0, C2, C0, 0
    BX LR    

_mmu_write_dacr:
    MCR P15, 0, R0, C3, C0, 0
    BX LR

_mmu_read_dacr:
    MRC P15, 0, R0, C3, C0, 0
    BX LR

_mmu_write_cr:
    MCR P15, 0, R0, C1, C0, 0 
    BX LR

_mmu_read_cr:
    MRC P15, 0, R0, C1, C0, 0 
    BX LR

_mmu_enable:
    MRC p15, 0, R4, c1, c0, 0    // Leer reg. control.
    ORR R4, R4, #0x1            // Bit 0 es habilitación de MMU.
    MCR p15, 0, R4, c1, c0, 0   // Escribir reg. control.
    BX LR

_mmu_disable:
    MRC p15, 0, R4, c1, c0, 0    // Leer reg. control.
    BIC R4, R4, #0x1            // Bit 0 es habilitación de MMU.
    MCR p15, 0, R4, c1, c0, 0   // Escribir reg. control.
    BX LR
