.global _start


.section .stack
	.space 0x1000

.section .bootloader,"ax"@progbits


//Comienzo de codigo de test
_start:
	LDR SP,=STACK_END

	LDR R0, =KERNEL_INIT
	LDR R1, =KERNEL_LOAD
	LDR R2, =KERNEL_SIZE
	BL memcpy

	BL kernel_start
end:
	B .
//Fin de codigo de test


// Subrutina memcpy
// Copia una cierta cantidad de bytes partiendo de una
// direccion dada de memoria a otra direccion de memoria
//
// r0: Direccion de memoria destino
// r1: Direccion de memoria fuente
// r2: Cantidad de bytes que se deben copiar
//
// Comienzo de codigo de memcpy
memcpy:
	CMP R2, #0
	BEQ memcpy_end

memcpy_loop:
	LDRB R3, [R1], #1
	STRB R3, [R0], #1
	SUBS R2, R2, #1
	BNE memcpy_loop

memcpy_end:
	BX LR
//Fin de codigo de memcpy


.section .kernel,"ax"@progbits
	kernel_start:
	LDR R0, =0x70080000
	LDR R1, =12
	STR R1, [R0]
	BX LR

