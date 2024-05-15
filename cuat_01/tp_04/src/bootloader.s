/*
Esta archivo contiene el codigo del bootlader.
Encargado de copiar el kernel a RAM, copiar el ISR a su direccion
y comenzar la ejecucion del kernel
*/


/* Simbolos definidos por el linker script */
.extern _KERNEL_INIT
.extern _KERNEL_LOAD
.extern _KERNEL_SIZE
.extern _ISR_INIT
.extern _ISR_LOAD
.extern _ISR_SIZE

.global _start

.equ USR_MODE, 0x10    /* USER       - Encoding segun ARM B1.3.1 (pag. B1-1139): 10000 - Bits 4:0 del CPSR */
.equ FIQ_MODE, 0x11    /* FIQ        - Encoding segun ARM B1.3.1 (pag. B1-1139): 10001 - Bits 4:0 del CPSR */
.equ IRQ_MODE, 0x12    /* IRQ        - Encoding segun ARM B1.3.1 (pag. B1-1139): 10010 - Bits 4:0 del CPSR */
.equ SVC_MODE, 0x13    /* Supervisor - Encoding segun ARM B1.3.1 (pag. B1-1139): 10011 - Bits 4:0 del CPSR */
.equ ABT_MODE, 0x17    /* Abort      - Encoding segun ARM B1.3.1 (pag. B1-1139): 10111 - Bits 4:0 del CPSR */
.equ UND_MODE, 0x1B    /* Undefined  - Encoding segun ARM B1.3.1 (pag. B1-1139): 11011 - Bits 4:0 del CPSR */
.equ SYS_MODE, 0x1F    /* System     - Encoding segun ARM B1.3.1 (pag. B1-1139): 11111 - Bits 4:0 del CPSR */
.equ I_BIT,    0x80    /* Mask bit I - Encoding segun ARM B1.3.3 (pag. B1-1149) - Bit 7 del CPSR */
.equ F_BIT,    0x40    /* Mask bit F - Encoding segun ARM B1.3.3 (pag. B1-1149) - Bit 6 del CPSR */


.section .bootloader,"ax"@progbits
//Comienzo del main del bootloader
_start:

	// Copia el kernel a RAM
	LDR R0, =_KERNEL_INIT //VMA del kernel (donde se va a copiar)
	LDR R1, =_KERNEL_LOAD //LMA del kernel (codigo de origen)
	LDR R2, =_KERNEL_SIZE //Tamano del kernel
	BL memcpy

	// Copia el ISR a su direccion de inicio
	LDR R0, =_ISR_INIT //VMA del ISR (donde se va a copiar)
	LDR R1, =_ISR_LOAD //LMA del ISR (codigo de origen)
	LDR R2, =_ISR_SIZE //Tamano del ISR
	BL memcpy


_stack_init:
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
	LDR R0, =kernel_start
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





