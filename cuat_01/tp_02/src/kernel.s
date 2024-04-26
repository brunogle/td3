/*
Este archivo contiene el codigo del kernel.
Que es copiado de ROM a RAM por el bootloader
*/


.global kernel_start

.thumb 

.section .kernel,"ax"@progbits

	/* Codigo del kernel (ejemplo) */
	kernel_start:
	LDR R0, =0x70080000
	LDR R1, =12
	STR R1, [R0]
	B .

