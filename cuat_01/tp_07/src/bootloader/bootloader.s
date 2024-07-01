/*
Este archivo contiene el codigo del bootlader y es el punto de inicio
del proyecto.

La funcion del bootloader es copiar los datos que son cargados
en ROM a RAM y configura los stack pointers de cada modo de
operacion.

Luego de esto, salta a la ejecucion del codigo del kernel.
*/


.include "src/cpu_defines.s"

.global _start

.section .text.bootloader.start

//Comienzo del main del bootloader
_start:
	// Copia el kernel a RAM
 	LDR R0, =_TEXT_INIT //VMA del .text
	LDR R1, =_TEXT_LOAD //LMA del .text
	LDR R2, =_TEXT_SIZE //Tamaño del .text
	BL _util_memcpy

	// Copia los datos inicializados a RAM
 	LDR R0, =_DATA_INIT //VMA de .data
	LDR R1, =_DATA_LOAD //LMA de .data
	LDR R2, =_DATA_SIZE //Tamaño de .data
	BL _util_memcpy

	// Copia los datos read-only a RAM
 	LDR R0, =_RODATA_INIT //VMA de .rodata
	LDR R1, =_RODATA_LOAD //LMA de .rodata
	LDR R2, =_RODATA_SIZE //Tamaño de .rodata
	BL _util_memcpy

	// Copia el ISR a su direccion de inicio
	LDR R0, =_ISR_INIT //VMA del ISR
	LDR R1, =_ISR_LOAD //LMA del ISR
	LDR R2, =_ISR_SIZE //Tamaño del ISR
	BL _util_memcpy

	// Copia el kernel a RAM
 	LDR R0, =_TASK1_TEXT_INIT //VMA del .text
	LDR R1, =_TASK1_TEXT_LOAD //LMA del .text
	LDR R2, =_TASK1_TEXT_SIZE //Tamaño del .text
	BL _util_memcpy

	// Copia los datos inicializados a RAM
 	LDR R0, =_TASK1_DATA_INIT //VMA de .data
	LDR R1, =_TASK1_DATA_LOAD //LMA de .data
	LDR R2, =_TASK1_DATA_SIZE //Tamaño de .data
	BL _util_memcpy

	// Copia los datos read-only a RAM
 	LDR R0, =_TASK1_RODATA_INIT //VMA de .rodata
	LDR R1, =_TASK1_RODATA_LOAD //LMA de .rodata
	LDR R2, =_TASK1_RODATA_SIZE //Tamaño de .rodata
	BL _util_memcpy

	// Copia el kernel a RAM
 	LDR R0, =_TASK2_TEXT_INIT //VMA del .text
	LDR R1, =_TASK2_TEXT_LOAD //LMA del .text
	LDR R2, =_TASK2_TEXT_SIZE //Tamaño del .text
	BL _util_memcpy

	// Copia los datos inicializados a RAM
 	LDR R0, =_TASK2_DATA_INIT //VMA de .data
	LDR R1, =_TASK2_DATA_LOAD //LMA de .data
	LDR R2, =_TASK2_DATA_SIZE //Tamaño de .data
	BL _util_memcpy

	// Copia los datos read-only a RAM
 	LDR R0, =_TASK2_RODATA_INIT //VMA de .rodata
	LDR R1, =_TASK2_RODATA_LOAD //LMA de .rodata
	LDR R2, =_TASK2_RODATA_SIZE //Tamaño de .rodata
	BL _util_memcpy

    /* Inicializamos los stack pointers para los diferentes modos de funcionamiento */
    MSR cpsr_c,#(IRQ_MODE)
    LDR SP,=__irq_stack_top__     /* IRQ stack pointer */
    MSR cpsr_c,#(FIQ_MODE)
    LDR SP,=__fiq_stack_top__     /* FIQ stack pointer */
    MSR cpsr_c,#(SVC_MODE)
    LDR SP,=__svc_stack_top__     /* SVC stack pointer */
    MSR cpsr_c,#(ABT_MODE)
    LDR SP,=__abt_stack_top__     /* ABT stack pointer */
    MSR cpsr_c,#(UND_MODE)
    LDR SP,=__und_stack_top__     /* UND stack pointer */
    MSR cpsr_c,#(SYS_MODE)
    LDR SP,=__sys_stack_top__     /* SYS stack pointer */

	// Paso a ejecutar el kernel en su nueva ubicacion
	LDR R0,=kernel_start
	BX R0
	
_end:
	B .
//Fin del main del bootloader


.end



