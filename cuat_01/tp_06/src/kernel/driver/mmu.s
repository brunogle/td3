.global _mmu_write_ttbr0, _mmu_read_ttbr0
.global _mmu_write_dacr, _mmu_read_dacr
.global _mmu_write_cr, _mmu_read_cr
.global _mmu_enable, _mmu_disable

.section .text.kernel

/*
Subrutina _mmu_write_ttbr0

Escribe en TTBR0.

Parametros:
    R0: Valor a escribir
*/
_mmu_write_ttbr0:
    MCR P15, 0, R0, C2, C0, 0
    BX LR


/*
Subrutina _mmu_read_ttbr0


Lee TTBR0.

Retorna:
    R0: Valor leido
*/
_mmu_read_ttbr0:
    MRC P15, 0, R0, C2, C0, 0
    BX LR    

/*
Subrutina _mmu_write_dacr

Escribe en DACR.

Parametros:
    R0: Valor a escribir
*/
_mmu_write_dacr:
    MCR P15, 0, R0, C3, C0, 0
    BX LR

/*
Subrutina _mmu_read_dacr

Lee DACR.

Retorna:
    R0: Valor leido
*/
_mmu_read_dacr:
    MRC P15, 0, R0, C3, C0, 0
    BX LR

/*
Subrutina _mmu_write_cr

Escribe en Control Register.

Parametros:
    R0: Valor a escribir
*/
_mmu_write_cr:
    MCR P15, 0, R0, C1, C0, 0 
    BX LR

/*
Subrutina _mmu_read_cr

Lee Control Register.

Retorna:
    R0: Valor leido
*/
_mmu_read_cr:
    MRC P15, 0, R0, C1, C0, 0 
    BX LR

/*
Subrutina _mmu_enable

Habilita MMU
*/
_mmu_enable:
    MRC p15, 0, R4, c1, c0, 0   // Lee registro VMSA (coprocesador 15)
    ORR R4, R4, #0x1            // Setea el bit 0: Habilita la MMU
    MCR p15, 0, R4, c1, c0, 0   // Escribe registro VMSA (coprocesador 15)
    BX LR

/*
Subrutina _mmu_disable

Deshabilita MMU
*/
_mmu_disable:
    MRC p15, 0, R4, c1, c0, 0   // Lee registro VMSA (coprocesador 15) 
    BIC R4, R4, #0x1            // Resetea el bit 0: Habilita la MMU
    MCR p15, 0, R4, c1, c0, 0   // Escribe registro VMSA (coprocesador 15)
    BX LR
