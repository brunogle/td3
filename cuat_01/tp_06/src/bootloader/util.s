.section .text.bootloader

.global _util_memcpy

/*
Subrutina _util_memcpy

Copia una cierta cantidad de bytes partiendo de una
direccion dada de memoria a otra direccion de memoria


Parametros:
	R0: Direccion de memoria destino
	R1: Direccion de memoria fuente
	R2: Cantidad de bytes que se deben copiar
*/
_util_memcpy:
	CMP R2, #0
	BEQ util_memcpy_end

util_memcpy_loop:
	LDRB R3, [R1], #1
	STRB R3, [R0], #1
	SUBS R2, R2, #1
	BNE util_memcpy_loop

util_memcpy_end:
	BX LR
/*
Fin de codigo de util_memcpy
*/


.end
