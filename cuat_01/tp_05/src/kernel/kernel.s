/*
Este archivo contiene el codigo del kernel.
Que es copiado de ROM a RAM por el bootloader
*/

.include "src/util/addr.s"

.global kernel_start

.extern _L1_PAGE_TABLES_INIT

.section .kernel,"ax"@progbits


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


	/* Codigo del kernel (ejemplo) */
	kernel_start:

	BL _gic_timer_0_1_enable

	BL _gic_enable //Habilito en GIC

	BL _irq_enable //Habilito IRQ (importante habilitarlo despues de configurar el GIC)

	BL _timer0_10ms_tick_enable

	// Esto crearia una exepcion, va a escribir "MEM" en el registro, enteonces no va a contar desde 0,
	// va a contar desde 0x004D454D si esto se ejecuta
	
	LDR R0, =0
	BL _fill_tables_identity_mapping

    LDR R0,=_L1_PAGE_TABLES_INIT
	BL _mmu_write_ttbr0

	LDR R0, =0x55555555
	BL _mmu_write_dacr

	BL _mmu_enable
	
	interrupt_loop:
		WFI
		NOP
		B interrupt_loop // Cuando sale de IRQ se viene aca, si no pongo el NOP se me sae del loop. Porque pasa esto???
	 

