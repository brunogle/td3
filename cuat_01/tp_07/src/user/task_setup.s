/*
Este es el unico archivo que debe ser modificado por el usuario para
agregar tareas a la ejecucion.
*/


.include "src/cpu_defines.s"

.global _user_defined_section_map
.global _list_task_text_init, _list_task_text_load, _list_task_text_size
.global _list_task_data_init, _list_task_data_load, _list_task_data_size
.global _list_task_stack_init, _list_task_stack_size
.global _list_task_bss_init, _list_task_bss_size
.global _list_task_rodata_init, _list_task_rodata_load, _list_task_rodata_size
.global _list_task_entrypoint
.global _list_task_pagetables
.global task_count

.section .text.kernel


/*
Subrutina _user_defined_section_map

Esta subrutina se ejecuta cuando despues de mapear el resto de las secciones
de las tareas del usuario. Sirve para que el usuario pueda mapear secciones
adicionales solamente modificando este archivo
*/
_user_defined_section_map:
    PUSH {LR}

	LDR R0, =_TASK1_READINGAREA_INIT
	LDR R1, =_TASK1_READINGAREA_SIZE
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
    LDR R3, =TASK1_L1_PAGE_TABLES_INIT
	BL _identiy_map_memory_range


	LDR R0, =_TASK2_READINGAREA_INIT
	LDR R1, =_TASK2_READINGAREA_SIZE
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
    LDR R3, =TASK2_L1_PAGE_TABLES_INIT
	BL _identiy_map_memory_range

    POP {LR}
    BX LR

.section .data

/*
Todas las direcciones de memoria de las taeas deben ser ubicadas en
los siguientes arrays para que el kernel pueda mapearlas adecuadamente
*/

_list_task_text_init: .word _TASK1_TEXT_INIT, _TASK2_TEXT_INIT
_list_task_text_load: .word _TASK1_TEXT_LOAD, _TASK2_TEXT_LOAD
_list_task_text_size: .word _TASK1_TEXT_SIZE, _TASK2_TEXT_SIZE

_list_task_data_init: .word _TASK1_DATA_INIT, _TASK2_DATA_INIT
_list_task_data_load: .word _TASK1_DATA_LOAD, _TASK2_DATA_LOAD
_list_task_data_size: .word _TASK1_DATA_SIZE, _TASK2_DATA_SIZE

_list_task_stack_init: .word _TASK1_STACK_INIT, _TASK2_STACK_INIT
_list_task_stack_size: .word _TASK1_STACK_SIZE, _TASK2_STACK_SIZE

_list_task_bss_init: .word _TASK1_BSS_INIT, _TASK2_BSS_INIT
_list_task_bss_size: .word _TASK1_BSS_SIZE, _TASK2_BSS_SIZE

_list_task_rodata_init: .word _TASK1_RODATA_INIT, _TASK2_RODATA_INIT
_list_task_rodata_load: .word _TASK1_RODATA_LOAD, _TASK2_RODATA_LOAD
_list_task_rodata_size: .word _TASK1_RODATA_SIZE, _TASK2_RODATA_SIZE

/*
Puntos de entrada de las tareas
*/
_list_task_entrypoint: .word _task1, _task2

/*
Direcciones de las tablas de paginacion definidas mas abajo.
*/
_list_task_pagetables: .word TASK1_L1_PAGE_TABLES_INIT, TASK2_L1_PAGE_TABLES_INIT

/*
Acordata de actualizar la cantidad de tareas que se estaran ejecutando!
*/
task_count: .word 2



.section .bss.kernel


/*
Las tablas de paginacion se deben describir aca.
Tienen que estar alineadas con .align 14
Y las direcciones agregadas a _list_task_pagetables
*/
.align 14
TASK1_L1_PAGE_TABLES_INIT:
.space 0x4000

.align 14
TASK2_L1_PAGE_TABLES_INIT:
.space 0x4000


