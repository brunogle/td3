.section .text.kernel

.equ IDNTY_MAP_EXECUTABLE, 0x1
.equ IDNTY_MAP_RW, 0x2
.equ IDNTY_MAP_CACHE_EN, 0x4
.equ IDNTY_MAP_GLOBAL, 0x8
.equ IDNTY_MAP_UNPRIV_ACCESS, 0x100

.equ IDNTY_MAP_DOMAIN_0, 0x00
.equ IDNTY_MAP_DOMAIN_1, 0x10
.equ IDNTY_MAP_DOMAIN_2, 0x20
.equ IDNTY_MAP_DOMAIN_3, 0x30
.equ IDNTY_MAP_DOMAIN_4, 0x40
.equ IDNTY_MAP_DOMAIN_5, 0x50
.equ IDNTY_MAP_DOMAIN_6, 0x60
.equ IDNTY_MAP_DOMAIN_7, 0x70
.equ IDNTY_MAP_DOMAIN_8, 0x80
.equ IDNTY_MAP_DOMAIN_9, 0x90
.equ IDNTY_MAP_DOMAIN_10, 0xA0
.equ IDNTY_MAP_DOMAIN_11, 0xB0
.equ IDNTY_MAP_DOMAIN_12, 0xC0
.equ IDNTY_MAP_DOMAIN_13, 0xD0
.equ IDNTY_MAP_DOMAIN_14, 0xE0
.equ IDNTY_MAP_DOMAIN_15, 0xF0


.global _copy_task_data, _identity_map_task_memory

_copy_task_data:
    PUSH {LR}

    /*
    =====================
        Tarea 1
    =====================
    */

 	LDR R0, =_TASK1_TEXT_INIT //VMA del .text
	LDR R1, =_TASK1_TEXT_LOAD //LMA del .text
	LDR R2, =_TASK1_TEXT_SIZE //Tamaño del .text
	BL _util_memcpy

 	LDR R0, =_TASK1_DATA_INIT //VMA de .data
	LDR R1, =_TASK1_DATA_LOAD //LMA de .data
	LDR R2, =_TASK1_DATA_SIZE //Tamaño de .data
	BL _util_memcpy

 	LDR R0, =_TASK1_RODATA_INIT //VMA de .rodata
	LDR R1, =_TASK1_RODATA_LOAD //LMA de .rodata
	LDR R2, =_TASK1_RODATA_SIZE //Tamaño de .rodata
	BL _util_memcpy

    /*
    =====================
        Tarea 2
    =====================
    */

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

    /*
    =======================================
    Ejemplo.
    Remplazar TASKNAME por nombre de tarea
    ========================================
    */

    /*
 	LDR R0, =_TASKNAME_TEXT_INIT //VMA del .text
	LDR R1, =_TASKNAME_TEXT_LOAD //LMA del .text
	LDR R2, =_TASKNAME_TEXT_SIZE //Tamaño del .text
	BL _util_memcpy

 	LDR R0, =_TASKNAME_DATA_INIT //VMA de .data
	LDR R1, =_TASKNAME_DATA_LOAD //LMA de .data
	LDR R2, =_TASKNAME_DATA_SIZE //Tamaño de .data
	BL _util_memcpy

 	LDR R0, =_TASKNAME_RODATA_INIT //VMA de .rodata
	LDR R1, =_TASKNAME_RODATA_LOAD //LMA de .rodata
	LDR R2, =_TASKNAME_RODATA_SIZE //Tamaño de .rodata
	BL _util_memcpy
    */

    POP {LR}
    BX LR

/*
Subrutina _identity_map_task_memory

Mapea una region de memoria para ser utilizada por una tarea.
El orden de las secciones es:
.text
.data
.bss
.rodata
stack

Cada sección es colocada en paginas distintas.

Parametros:
    R0: Direccion de comienzo de .text
    R1: Direccion de comienzo de .data
    R1: Tamaño de stack en bytes
*/
_identity_map_task_memory:
    PUSH {LR}

    /*
    =====================
        Tarea 1
    =====================
    */

    LDR R4, =_L1_PAGE_TABLES_INIT_TASK1

    MOV R0, R4
    BL _identity_map_kernel_sections

    //Text (Codigo de bootloader)
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_EXECUTABLE|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK1_TEXT_INIT
	LDR R1, =_TASK1_TEXT_SIZE
	BL _identiy_map_memory_range

    //BSS\
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK1_BSS_INIT
	LDR R1, =_TASK1_BSS_SIZE
	BL _identiy_map_memory_range

    //Data
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK1_DATA_INIT
	LDR R1, =_TASK1_DATA_SIZE
	BL _identiy_map_memory_range

    //RO-Data
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK1_RODATA_INIT
	LDR R1, =_TASK1_RODATA_SIZE
	BL _identiy_map_memory_range

    //Stack (Contiene los 6 stacks)
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK1_STACK_INIT
	LDR R1, =_TASK1_STACK_SIZE
	BL _identiy_map_memory_range

    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK1_READINGAREA_INIT
	LDR R1, =_TASK1_READINGAREA_SIZE
	BL _identiy_map_memory_range


    /*
    =====================
        Tarea 2
    =====================
    */

    LDR R4, =_L1_PAGE_TABLES_INIT_TASK2

    MOV R0, R4
    BL _identity_map_kernel_sections


    //Text (Codigo de bootloader)
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_EXECUTABLE|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK2_TEXT_INIT
	LDR R1, =_TASK2_TEXT_SIZE
	BL _identiy_map_memory_range

    //BSS
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK2_BSS_INIT
	LDR R1, =_TASK2_BSS_SIZE
	BL _identiy_map_memory_range

    //Data
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK2_DATA_INIT
	LDR R1, =_TASK2_DATA_SIZE
	BL _identiy_map_memory_range

    //RO-Data
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK2_RODATA_INIT
	LDR R1, =_TASK2_RODATA_SIZE
	BL _identiy_map_memory_range

    //Stack (Contiene los 6 stacks)
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK2_STACK_INIT
	LDR R1, =_TASK2_STACK_SIZE
	BL _identiy_map_memory_range

    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASK2_READINGAREA_INIT
	LDR R1, =_TASK2_READINGAREA_SIZE
	BL _identiy_map_memory_range


    /*
    =======================================
    Ejemplo.
    Remplazar TASKNAME por nombre de tarea
    ========================================
    */

    /*
    LDR R4, =_L1_PAGE_TABLES_INIT_TASKNAME

    MOV R0, R4
    BL _identity_map_kernel_sections


    //Text (Codigo de bootloader)
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_EXECUTABLE|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASKNAME_TEXT_INIT
	LDR R1, =_TASKNAME_TEXT_SIZE
	BL _identiy_map_memory_range

    //BSS
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASKNAME_BSS_INIT
	LDR R1, =_TASKNAME_BSS_SIZE
	BL _identiy_map_memory_range

    //Data
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASKNAME_DATA_INIT
	LDR R1, =_TASKNAME_DATA_SIZE
	BL _identiy_map_memory_range

    //RO-Data
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASKNAME_RODATA_INIT
	LDR R1, =_TASKNAME_RODATA_SIZE
	BL _identiy_map_memory_range

    //Stack (Contiene los 6 stacks)
    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASKNAME_STACK_INIT
	LDR R1, =_TASKNAME_STACK_SIZE
	BL _identiy_map_memory_range

    MOV R3, R4
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_UNPRIV_ACCESS)
	LDR R0, =_TASKNAME_READINGAREA_INIT
	LDR R1, =_TASKNAME_READINGAREA_SIZE
	BL _identiy_map_memory_range
    
    */

    POP {LR}
    BX LR


.section .bss
.global _L1_PAGE_TABLES_INIT_TASK1
.align 14
_L1_PAGE_TABLES_INIT_TASK1:
.space 0x4000

.global _L1_PAGE_TABLES_INIT_TASK2
.align 14
_L1_PAGE_TABLES_INIT_TASK2:
.space 0x4000

/*
=======================================
Ejemplo.
Remplazar TASKNAME por nombre de tarea
========================================
*/

/*
.global _L1_PAGE_TABLES_INIT_TASKNAME
.align 14
_L1_PAGE_TABLES_INIT_TASKNAME:
.space 0x4000
*/
