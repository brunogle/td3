/*
Este archivo contiene el codigo del bootlader y es el punto de inicio
del sistema operativo.

La funcion del bootloader es copiar los datos que son cargados
en ROM a RAM y configura los stack pointers de cada modo de
operacion para el kernel.

Luego de esto, salta a la ejecucion del codigo del kernel.
*/


.include "src/cpu_defines.s"

.global _start

.section .text.bootloader.start

//Comienzo del main del bootloader
//Punto de entrada del programa
_start:

	/*
	Copia el kernel de ROM a RAM
	*/

 	LDR R0, =_KERNEL_TEXT_INIT
	LDR R1, =_KERNEL_TEXT_LOAD
	LDR R2, =_KERNEL_TEXT_SIZE
	BL _bootloader_memcpy

 	LDR R0, =_KERNEL_DATA_INIT
	LDR R1, =_KERNEL_DATA_LOAD
	LDR R2, =_KERNEL_DATA_SIZE
	BL _bootloader_memcpy

 	LDR R0, =_KERNEL_RODATA_INIT
	LDR R1, =_KERNEL_RODATA_LOAD
	LDR R2, =_KERNEL_RODATA_SIZE
	BL _bootloader_memcpy

	LDR R0, =_ISR_INIT 
	LDR R1, =_ISR_LOAD 
	LDR R2, =_ISR_SIZE
	BL _bootloader_memcpy


    /*
	Inicializacion de los stack pointers para los distintos modos
	*/
    MSR cpsr_c,#(IRQ_MODE)
    LDR SP,=_IRQ_STACK_END
    MSR cpsr_c,#(FIQ_MODE)
    LDR SP,=_FIQ_STACK_END
    MSR cpsr_c,#(SVC_MODE)
    LDR SP,=_SVC_STACK_END
    MSR cpsr_c,#(ABT_MODE)
    LDR SP,=_ABT_STACK_END
    MSR cpsr_c,#(UND_MODE)
    LDR SP,=_UND_STACK_END
    MSR cpsr_c,#(SYS_MODE)
    LDR SP,=_SYS_STACK_END

	// Paso a ejecutar el kernel en su nueva ubicacion en modo SYS
	CPS #SYS_MODE
	LDR PC,=kernel_start
	
_bootloader_end:
	B .
//Fin del main del bootloader



.section .text.bootloader

/*
Subrutina _bootloader_memcpy

Copia una cierta cantidad de bytes partiendo de una
direccion dada de memoria a otra direccion de memoria


Parametros:
	R0: Direccion de memoria destino
	R1: Direccion de memoria fuente
	R2: Cantidad de bytes que se deben copiar
*/
_bootloader_memcpy:
	CMP R2, #0
	BEQ bootloader_memcpy_end

	bootloader_memcpy_loop:
		LDRB R3, [R1], #1
		STRB R3, [R0], #1
		SUBS R2, R2, #1
		BNE bootloader_memcpy_loop

	bootloader_memcpy_end:
	BX LR
/*
Fin de codigo de _bootloader_memcpy
*/




.end


