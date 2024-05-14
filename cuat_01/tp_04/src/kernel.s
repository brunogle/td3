/*
Este archivo contiene el codigo del kernel.
Que es copiado de ROM a RAM por el bootloader
*/

.include "src/addr.s"

.global kernel_start


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



	BL _gic_enable //Habilito en GIC

	BL _timer0_enable //Habilito timer 0, preconfigurado para un tick rate de 10ms

	LDR R10,=0 // Preparo R10 para contar

	BL _irq_enable //Habilito IRQ (importante habilitarlo despues de configurar el GIC)


	loop_start:

	LDR R9,=0xFFFFFFFF
	//STR R9,[R9]   // Esto crearia una exepcion

	interrupt_loop:
		WFI
		B interrupt_loop
	 

