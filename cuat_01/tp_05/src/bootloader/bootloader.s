/*
Este archivo contiene el codigo del bootlader.

La funcion del bootloader es:
	Copiar el kernel a RAM (en KERNEL_INIT)
	Copiar el ISR a la direccion _ISR_INIT
	Configurar los distintos stack pointers
	Comienza la ejecucion del kernel
*/


/* Simbolos definidos por el linker script */
.extern _TEXT_INIT
.extern _TEXT_LOAD
.extern _TEXT_SIZE
.extern _ISR_INIT
.extern _ISR_LOAD
.extern _ISR_SIZE

.global _start


.section .bootloader,"ax"@progbits

.include "src/util/addr.s"


//Comienzo del main del bootloader
_start:
	// Copia el kernel a RAM
	LDR R0, =_TEXT_INIT //VMA del kernel (donde se va a copiar)
	LDR R1, =_TEXT_LOAD //LMA del kernel (codigo de origen)
	LDR R2, =_TEXT_SIZE //Tamano del kernel
	BL _util_memcpy

	// Copia el ISR a su direccion de inicio
	LDR R0, =_ISR_INIT //VMA del ISR (donde se va a copiar)
	LDR R1, =_ISR_LOAD //LMA del ISR (codigo de origen)
	LDR R2, =_ISR_SIZE //Tamano del ISR
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



