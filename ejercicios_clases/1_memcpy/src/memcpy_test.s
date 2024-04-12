.global _start
.section .text


//Comienzo de codigo de test
_start:
      LDR R0, =data_destino
      LDR R1, =data_fuente
      MOV R2, #10
      BL memcpy
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


.section .data
data_fuente: .byte 10,20,30,40,50,60,70,80,90,100
data_destino: .byte 0,0,0,0,0,0,0,0,0,0
