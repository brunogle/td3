.global _start

.extern


.equ KB,1024
.equ PILA_SIZE,32*KB

.section .pila
	.space PILA_SIZE

.section .bootloader


//Comienzo de codigo de test
_start:
      LDR R0, =__DESTINO_KERNEL
      LDR R1, =.kernel
      MOV R2, #10
      BL memcpy
	  BL kernel_start
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


.section .kernel
	kernel_start:
	MOV R0, #0x70080000
	MOV R1, #12
	STR R1, [R0]
	B .



