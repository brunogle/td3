.include "src/addr.s"

.global _identity_map_all_sections

.section .text_kernel,"ax"@progbits


/*
Subrutina _identity_map_all_sections

Realiza un identity mapping de toda la memoria de interes.
Las secciones mapeadas son:
    Tabla ISR (.isr_table)
    Stack (.stack)
    Codigo (.text)
    Direcciones mapeadas al GIC
    Direcciones mapeadas al Timers
*/
_identity_map_all_sections:
    STMFD   SP!, {R0-R3, LR}

    LDR R2, =0 //Todas estas secciones son datos, no son ejecutables

	LDR R0, =_STACK_INIT
	LDR R1, =_STACK_SIZE
	BL _identiy_map_memory_range

	LDR R0, =GIC_REGMAP_INIT
	LDR R1, =GIC_REGMAP_SIZE
	BL _identiy_map_memory_range

	LDR R0, =TIMER_REGMAP_INIT
	LDR R1, =TIMER_REGMAP_SIZE
	BL _identiy_map_memory_range
    
    LDR R2, =1 //Todas estas secciones son codigo, son ejecutables

    LDR R0, =_ISR_INIT
	LDR R1, =_ISR_SIZE
	BL _identiy_map_memory_range

	LDR R0, =_TEXT_INIT
	LDR R1, =_TEXT_SIZE
	BL _identiy_map_memory_range

    LDMFD   SP!, {R0-R3, LR}
    BX LR