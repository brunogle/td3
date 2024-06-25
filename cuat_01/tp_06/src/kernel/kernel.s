/*
Este archivo contiene el codigo del kernel.
Que es copiado de ROM a RAM por el bootloader
*/


.include "src/cpu_defines.s"

.global kernel_start
.global systick_count

.extern _L1_PAGE_TABLES_INIT


.section .text.kernel


	/* Codigo del kernel */
	kernel_start:

	CPS #SYS_MODE

	// Configuro DACR
	LDR R0, =0x1
	BL _mmu_write_dacr

	// Configuro TTBR0
	LDR R0,=_L1_PAGE_TABLES_INIT
	BL _mmu_write_ttbr0

	// Escribo tablas de paginacion
	BL _identity_map_kernel_sections
	BL _identity_map_task_memory

	// Habilito MMU
	BL _mmu_enable

	//Habilito IRQ (importante habilitarlo despues de configurar el GIC)
	BL _irq_enable

	BL _init_scheduler

	LDR R0, =_task1
	LDR R1, =_L1_PAGE_TABLES_INIT_TASK1
	BL _add_task

	LDR R0, =_task2
	LDR R1, =_L1_PAGE_TABLES_INIT_TASK2
	BL _add_task

	//Configuro y habilito GIC
	BL _gic_timer_0_1_enable
	BL _gic_enable 
	
	BL _start_scheduler


	interrupt_loop:
		WFI
		B interrupt_loop
	 


.section .data
systick_count: .word 0

.section .rodata
.space 4