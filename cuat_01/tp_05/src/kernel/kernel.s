/*
Este archivo contiene el codigo del kernel.
Que es copiado de ROM a RAM por el bootloader
*/

.include "src/addr.s"

.global kernel_start

.extern _L1_PAGE_TABLES_INIT


.section .text_kernel,"ax"@progbits


	/* Codigo del kernel */
	kernel_start:
	
	SWI 0  // Pruebo un SVC

	// Configuro DACR
	LDR R0, =0x55555555
	BL _mmu_write_dacr

	// Configuro TTBR0
	LDR R0,=_L1_PAGE_TABLES_INIT
	BL _mmu_write_ttbr0

	// Escribo tablas de paginacion
	BL _identity_map_all_sections

	// Habilito MMU
	BL _mmu_enable

	//Preparo count y habilito timer
	LDR R10,=0
	BL _timer0_10ms_tick_enable

	//Habilito IRQ (importante habilitarlo despues de configurar el GIC)
	BL _irq_enable

	//Configuro y habilito GIC
	BL _gic_timer_0_1_enable
	BL _gic_enable 


	interrupt_loop:
		WFI
		NOP
		B interrupt_loop // Cuando sale de IRQ se viene aca, si no pongo el NOP se me sae del loop. Porque pasa esto???
	 

