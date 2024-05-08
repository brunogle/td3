/*
Este archivo contiene el codigo del kernel.
Que es copiado de ROM a RAM por el bootloader
*/


.global kernel_start


.section .kernel,"ax"@progbits


	/*
	Habilita interrupciones
	*/
	.align 4             // Alineado a 4 Bytes
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
	.align 4             // Alineado a 4 Bytes
	_irq_disable:
		DSB
		MRS R0, CPSR
		ORR R0, #0x40
		MSR CPSR, R0
		DSB
		ISB
		BX LR


	/* Codigo del kernel (ejemplo) */
	kernel_start:

	BL _irq_enable

	SWI 95

	B .

