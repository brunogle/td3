/*
Este archivo contiene el codigo del kernel.
Que es copiado de ROM a RAM por el bootloader
*/

.include "src/util/addr.s"

.global kernel_start

.extern _L1_PAGE_TABLES_INIT

.section .text_kernel,"ax"@progbits


	/* Codigo del kernel */
	kernel_start:
	

	//Configuro y habilito GIC
	BL _gic_timer_0_1_enable
	BL _gic_enable 

	// Completo translation tables en identity mapping
	LDR R0, =0 // NX = 0 (Permito la ejecucion de codigo en toda la memoria)
	BL _fill_tables_identity_mapping

	// Configuro TTBR0
	LDR R0,=_L1_PAGE_TABLES_INIT
	BL _mmu_write_ttbr0

	// Configuro DACR
	LDR R0, =0x55555555
	BL _mmu_write_dacr

	// Habilito MMU
	BL _mmu_enable

	//Habilito IRQ (importante habilitarlo despues de configurar el GIC)
	BL _irq_enable

	//Habilito timer
	BL _timer0_10ms_tick_enable

	interrupt_loop:
		WFI
		NOP
		B interrupt_loop // Cuando sale de IRQ se viene aca, si no pongo el NOP se me sae del loop. Porque pasa esto???
	 

