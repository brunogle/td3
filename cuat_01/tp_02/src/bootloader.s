/*
Esta archivo contiene el codigo del bootlader.
Encargado de copiar el kernel a RAM
*/


/* Simbolos definidos por el linker script */
.extern KERNEL_INIT
.extern KERNEL_LOAD
.extern KERNEL_SIZE
.extern STACK_END
.extern STACK_SIZE

.global _start


.section .stack //Espacio vacio para el stack
	.space =STACK_SIZE


.section .bootloader,"ax"@progbits
//Comienzo del main del bootloader
_start:
	LDR SP,=STACK_END //Configuro el stack pointer

	LDR R0, =KERNEL_INIT //VMA del kernel (donde se va a copiar)
	LDR R1, =KERNEL_LOAD //LMA del kernel (codigo de origen)
	LDR R2, =KERNEL_SIZE //Tamano del kernel
	BL memcpy

	// Paso a ejecutar el kernel en su nueva ubicacion
	LDR R0, =kernel_start
	ADD R0, #1 //Preparo para ejecutar en modo Thumb.
	BX R0
	
_end:
	B .
//Fin del main del bootloader


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





