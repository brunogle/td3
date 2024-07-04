/*
Este archivo contiene el punto de inicio del kernel.
*/

.include "src/kernel/config.s"

.global kernel_start
.global systick_count


.section .text.kernel


/* Punto de entrada del kernel */
kernel_start:

	/*
	Configuracion DACR:
	Domain 0: Client
	Domain 1: Manager
	Domain 2-15: No Access
	*/
	LDR R0, =0xD
	BL _mmu_write_dacr


	/*
	Escribo paginas del kernel.
	El kernel solamente se mapea a si mismo, en modo manager.
	*/
	LDR R0,=_KERNEL_L1_PAGE_TABLES_INIT
	LDR R1, =IDNTY_MAP_DOMAIN_1
	BL _identity_map_kernel_sections

	/*
	Escribo paginas de tareas.
	Cada tabla para cada tarea mapea con dominio cliente:
	-Memoria del kernel (solo accesible en modos privilegiados)
	-Codigo de usuario (accesible en todos los modos)
	*/
	BL _identity_map_task_memory

	/*
	Copio codigo y datos de las tareas de ROM a RAM
	*/
	BL _copy_task_data

	/*
	Preparo la MMU para que use las tablas para el kernel
	*/
	LDR R0,=_KERNEL_L1_PAGE_TABLES_INIT
	BL _mmu_write_ttbr0

	// Habilito MMU
	BL _mmu_enable

	//Habilito IRQ
	BL _irq_enable

	/*
	Itera por todas las tareas y las agrega al TCB
	*/
	BL _add_tasks_to_scheduler

	/*
	Configuro y habilito GIC
	*/
	BL _gic_timer_0_1_enable
	BL _gic_enable 

	/*
	Comienzo el scheduler.
	En este punto, se inicializa el scheduler, y este comienza
	ejecutando la tarea de sleep, del cual saldrá dentro en la
	siguiente interrupcion del timer, y comenzará a ejecutar
	la primer tarea agregada.
	*/
	BL _start_scheduler


	B . //Esto nunca se deberia ejecutar

	//Fin del codigo del kernel



/*
Subrutina _add_tasks_to_scheduler

Esta subrutina itera por todas las tareas, y agrega las tareas al
TCB utilizando la subrutina _add_task del scheduler.

Al TCB se escribe:
	-El punto de entrada
	-La direccion de las pagetables para la tarea
	-El stack pointer de inicio de la tarea

*/
_add_tasks_to_scheduler:
    PUSH {LR}
    LDR R5, =task_count
    LDR R5, [R5]


    MOV R4, #0
    LDR R6, =_list_task_entrypoint
    LDR R7, =_list_task_pagetables
    LDR R8, =_list_task_stack_init
    task_add_to_scehd_loop:
        LDR R0, [R6]
        LDR R1, [R7]
        LDR R2, [R8]
        BL _add_task
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_add_to_scehd_loop_end
        ADD R6, R6, #4
        ADD R7, R7, #4
        ADD R8, R8, #4
        B task_add_to_scehd_loop
    B task_add_to_scehd_loop
    task_add_to_scehd_loop_end:

    POP {LR}
    BX LR

/*
Subrutina _copy_task_data

Esta subrutina copia el codigo y datos de las tareas desde ROM a RAM.
*/
_copy_task_data:
    PUSH {LR}

    LDR R5, =task_count
    LDR R5, [R5]

    MOV R4, #0
    LDR R6, =_list_task_text_init
    LDR R7, =_list_task_text_load
    LDR R8, =_list_task_text_size
    task_text_copy_loop:
        LDR R0, [R6]
        LDR R1, [R7]
        LDR R2, [R8]
        BL _util_memcpy
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_text_copy_loop_end
        ADD R6, R6, #4
        ADD R7, R7, #4
        ADD R8, R8, #4
        B task_text_copy_loop
    B task_text_copy_loop
    task_text_copy_loop_end:


    MOV R4, #0
    LDR R6, =_list_task_data_init
    LDR R7, =_list_task_data_load
    LDR R8, =_list_task_data_size
    task_data_copy_loop:
        LDR R0, [R6]
        LDR R1, [R7]
        LDR R2, [R8]
        BL _util_memcpy
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_data_copy_loop_end
        ADD R6, R6, #4
        ADD R7, R7, #4
        ADD R8, R8, #4
        B task_data_copy_loop
    B task_data_copy_loop
    task_data_copy_loop_end:

    MOV R4, #0
    LDR R6, =_list_task_rodata_init
    LDR R7, =_list_task_rodata_load
    LDR R8, =_list_task_rodata_size
    task_rodata_copy_loop:
        LDR R0, [R6]
        LDR R1, [R7]
        LDR R2, [R8]
        BL _util_memcpy
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_rodata_copy_loop_end
        ADD R6, R6, #4
        ADD R7, R7, #4
        ADD R8, R8, #4
        B task_rodata_copy_loop
    B task_rodata_copy_loop
    task_rodata_copy_loop_end:

    POP {LR}
    BX LR

/*
Subrutina _identity_map_task_memory

Itera por todas las tareas y para cada una mapea:
	-Todo kernel (solo accsesible con privilegios)
	-El .text, .data, .bss, .rodata y stack correspondiente
	-Adicionalmente, ejecuta _user_defined_section_map para que el usuario
		pueda definir sus propias secciones.
*/


_identity_map_task_memory:
    PUSH {LR}



    LDR R5, =task_count
    LDR R5, [R5]
    
    /*
    Mapeo de memoria de kernel
    */
    MOV R4, #0
    LDR R6, =_list_task_pagetables
    task_pagetable_kernel_map_loop:
        LDR R0, [R6]
        LDR R1, =IDNTY_MAP_DOMAIN_0
        BL _identity_map_kernel_sections
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_pagetable_kernel_map_loop_end
        ADD R6, R6, #4
        B task_pagetable_kernel_map_loop
    B task_pagetable_kernel_map_loop
    task_pagetable_kernel_map_loop_end:

	/*
    Mapeo de .text de la tarea
    */
    MOV R4, #0
    LDR R6, =_list_task_text_init
    LDR R7, =_list_task_text_size
    LDR R8, =_list_task_pagetables
    task_pagetable_text_map_loop:
        LDR R0, [R6]
        LDR R1, [R7]
        LDR R2, =USER_TEXT_PAGE_ATTRIBUTES
        LDR R3, [R8]
        BL _identiy_map_memory_range
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_pagetable_text_map_loop_end
        ADD R6, R6, #4
        ADD R7, R7, #4
        ADD R8, R8, #4
        B task_pagetable_text_map_loop
    B task_pagetable_text_map_loop
    task_pagetable_text_map_loop_end:

	/*
    Mapeo de .data de la tarea
    */
    MOV R4, #0
    LDR R6, =_list_task_data_init
    LDR R7, =_list_task_data_size
    LDR R8, =_list_task_pagetables
    
    task_pagetable_data_map_loop:
        LDR R0, [R6]
        LDR R1, [R7]
        LDR R2, =USER_DATA_PAGE_ATTRIBUTES
        LDR R3, [R8]
        BL _identiy_map_memory_range
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_pagetable_data_map_loop_end
        ADD R6, R6, #4
        ADD R7, R7, #4
        ADD R8, R8, #4
        B task_pagetable_data_map_loop
    B task_pagetable_data_map_loop
    task_pagetable_data_map_loop_end:


	/*
    Mapeo de .bss de la tarea
    */
    MOV R4, #0
    LDR R6, =_list_task_bss_init
    LDR R7, =_list_task_bss_size
    LDR R8, =_list_task_pagetables
    
    task_pagetable_bss_map_loop:
        LDR R0, [R6]
        LDR R1, [R7]
        LDR R2, =USER_BSS_PAGE_ATTRIBUTES
        LDR R3, [R8]
        BL _identiy_map_memory_range
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_pagetable_bss_map_loop_end
        ADD R6, R6, #4
        ADD R7, R7, #4
        ADD R8, R8, #4
        B task_pagetable_bss_map_loop
    B task_pagetable_bss_map_loop
    task_pagetable_bss_map_loop_end:

	/*
    Mapeo de .rodata de la tarea
    */
    MOV R4, #0
    LDR R6, =_list_task_rodata_init
    LDR R7, =_list_task_rodata_size
    LDR R8, =_list_task_pagetables
    
    task_pagetable_rodata_map_loop:
        LDR R0, [R6]
        LDR R1, [R7]
        LDR R2, =USER_RODATA_PAGE_ATTRIBUTES
        LDR R3, [R8]
        BL _identiy_map_memory_range
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_pagetable_rodata_map_loop_end
        ADD R6, R6, #4
        ADD R7, R7, #4
        ADD R8, R8, #4
        B task_pagetable_rodata_map_loop
    B task_pagetable_rodata_map_loop
    task_pagetable_rodata_map_loop_end:


	/*
    Mapeo de stack de la tarea
    */
    MOV R4, #0
    LDR R6, =_list_task_stack_init
    LDR R7, =_list_task_stack_size
    LDR R8, =_list_task_pagetables
   
    task_pagetable_stack_map_loop:
        LDR R0, [R6]
        LDR R1, [R7]
        LDR R2, =USER_STACK_PAGE_ATTRIBUTES
        LDR R3, [R8]
        BL _identiy_map_memory_range
        ADD R4, R4, #1
        CMP R4, R5
        BEQ task_pagetable_stack_map_loop_end
        ADD R6, R6, #4
        ADD R7, R7, #4
        ADD R8, R8, #4
        B task_pagetable_stack_map_loop
    B task_pagetable_stack_map_loop
    task_pagetable_stack_map_loop_end:

	BL _user_defined_section_map
    
    POP {LR}
    BX LR



/*
Subrutina _identity_map_kernel_sections

Realiza un identity mapping de toda la memoria del kernel.
Esta subrutina se puede usar para mapear el kernel para las tareas de usuario
(Domain = 0) o para el kernel (Domain = 1)

Parametros:
    R0: Direccion de la tabla L1
    R1: Domain

*/
_identity_map_kernel_sections:
    PUSH {R4, LR}

    MOV R3, R0
    MOV R4, R1

    //Text
    LDR R2, =KERNEL_TEXT_PAGE_ATTRIBUTES
	ORR R2, R2, R4
    LDR R0, =_KERNEL_TEXT_INIT
	LDR R1, =_KERNEL_TEXT_SIZE
	BL _identiy_map_memory_range

    //BSS
    LDR R2, =KERNEL_BSS_PAGE_ATTRIBUTES
	ORR R2, R2, R4
    LDR R0, =_KERNEL_BSS_INIT
	LDR R1, =_KERNEL_BSS_SIZE
	BL _identiy_map_memory_range

    //Data
    LDR R2, =KERNEL_DATA_PAGE_ATTRIBUTES
	ORR R2, R2, R4
    LDR R0, =_KERNEL_DATA_INIT
	LDR R1, =_KERNEL_DATA_SIZE
	BL _identiy_map_memory_range

    //RO-Data
    LDR R2, =KERNEL_RODATA_PAGE_ATTRIBUTES
	ORR R2, R2, R4
    LDR R0, =_KERNEL_RODATA_INIT
	LDR R1, =_KERNEL_RODATA_SIZE
	BL _identiy_map_memory_range

    //Stack (Contiene los 6 stacks)
    LDR R2, =KERNEL_STACK_PAGE_ATTRIBUTES
	ORR R2, R2, R4
    LDR R0, =_KERNEL_STACK_INIT
	LDR R1, =_KERNEL_STACK_SIZE
	BL _identiy_map_memory_range

    //Registros GIC
    LDR R2, =KERNEL_PERIPHERAL_PAGE_ATTRIBUTES
	ORR R2, R2, R4
    LDR R0, =GIC_REGMAP_INIT
	LDR R1, =GIC_REGMAP_SIZE
	BL _identiy_map_memory_range

    //Registros Timer
    LDR R2, =KERNEL_PERIPHERAL_PAGE_ATTRIBUTES
	ORR R2, R2, R4
    LDR R0, =TIMER_REGMAP_INIT
	LDR R1, =TIMER_REGMAP_SIZE
	BL _identiy_map_memory_range

    //ISR
    LDR R2, =KERNEL_ISR_PAGE_ATTRIBUTES
	ORR R2, R2, R4
    LDR R0, =_ISR_INIT
	LDR R1, =_ISR_SIZE
	BL _identiy_map_memory_range

    POP {R4, LR}
    BX LR

.section .data.kernel

systick_count: .word 0 //Aumenta en 1 cada vez que Timer 0 causa un IRQ

.end
