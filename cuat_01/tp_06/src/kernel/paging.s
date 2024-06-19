.include "src/cpu_defines.s"

.global _identiy_map_memory_range
.global _identity_map_all_sections


.section .text_kernel,"ax"@progbits

.equ IDNTY_MAP_EXECUTABLE, 0x1
.equ IDNTY_MAP_RW, 0x2
.equ IDNTY_MAP_CACHE_EN, 0x4
.equ IDNTY_MAP_GLOBAL, 0x8

/*
Subrutina _identity_map_all_sections

Realiza un identity mapping de toda la memoria de interes.

*/
_identity_map_all_sections:
    PUSH {LR}

    LDR R3, =_L1_PAGE_TABLES_INIT

    //Text (Codigo de bootloader)
    LDR R2, =(IDNTY_MAP_EXECUTABLE|IDNTY_MAP_GLOBAL)
	LDR R0, =_TEXT_INIT
	LDR R1, =_TEXT_SIZE
	BL _identiy_map_memory_range

    //BSS
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_GLOBAL)
	LDR R0, =_BSS_INIT
	LDR R1, =_BSS_SIZE
	BL _identiy_map_memory_range

    //Data
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_GLOBAL)
	LDR R0, =_DATA_INIT
	LDR R1, =_DATA_SIZE
	BL _identiy_map_memory_range

    //RO-Data
    LDR R2, =(IDNTY_MAP_CACHE_EN|IDNTY_MAP_GLOBAL)
	LDR R0, =_RODATA_INIT
	LDR R1, =_RODATA_SIZE
	BL _identiy_map_memory_range

    //Stack (Contiene los 6 stacks)
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_GLOBAL)
	LDR R0, =_STACK_INIT
	LDR R1, =_STACK_SIZE
	BL _identiy_map_memory_range

    //Registros GIC
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_GLOBAL)
	LDR R0, =GIC_REGMAP_INIT
	LDR R1, =GIC_REGMAP_SIZE
	BL _identiy_map_memory_range

    //Registros Timer
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_GLOBAL)
	LDR R0, =TIMER_REGMAP_INIT
	LDR R1, =TIMER_REGMAP_SIZE
	BL _identiy_map_memory_range

    //ISR
    LDR R2, =(IDNTY_MAP_EXECUTABLE|IDNTY_MAP_GLOBAL)
	LDR R0, =_ISR_INIT
	LDR R1, =_ISR_SIZE
	BL _identiy_map_memory_range

    //Page tables
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_GLOBAL)
	LDR R0, =_PAGE_TABLES_INIT
	LDR R1, =_PAGE_TABLES_SIZE
	BL _identiy_map_memory_range


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
    R1: Tamaño de stack en bytes
*/
_identity_map_task_memory:
    //Text (Codigo de bootloader)
    LDR R2, =(IDNTY_MAP_EXECUTABLE|IDNTY_MAP_GLOBAL)
	LDR R0, =_TEXT_INIT
	LDR R1, =_TEXT_SIZE
	BL _identiy_map_memory_range

    //BSS
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_GLOBAL)
	LDR R0, =_BSS_INIT
	LDR R1, =_BSS_SIZE
	BL _identiy_map_memory_range

    //Data
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_GLOBAL)
	LDR R0, =_DATA_INIT
	LDR R1, =_DATA_SIZE
	BL _identiy_map_memory_range

    //RO-Data
    LDR R2, =(IDNTY_MAP_CACHE_EN|IDNTY_MAP_GLOBAL)
	LDR R0, =_RODATA_INIT
	LDR R1, =_RODATA_SIZE
	BL _identiy_map_memory_range

    //Stack (Contiene los 6 stacks)
    LDR R2, =(IDNTY_MAP_RW|IDNTY_MAP_CACHE_EN|IDNTY_MAP_GLOBAL)
	LDR R0, =_STACK_INIT
	LDR R1, =_STACK_SIZE
	BL _identiy_map_memory_range

/*
Subrutina _identiy_map_memory_range

Realiza un identity mapping en una region de memoria alineada a 4KiB.
Si ya existen las tablas L2, las reusa, y si no las crea.

La direccion desde donde se comienza el mapeo debe estar alineada a 4KiB.
Si el tamaño especificado no es multiplo de 4KiB, mapea la minima cantidad
necesaria para cubrir la region especificada (mapea en multiplos de 4KiB).

Esta subrutina puede aumentar el valor de next_l2_table_addr

Parametros:
    R0: Direccion desde donde paginar (0x-----000)
    R1: Tamaño de memoria que se desea paginar (Multiplo de 4KiB)
    R2: Configuracion:
        Bit0: Ejecutable, Si es 1 las paginas no son marcadas como nunca ejecutable (XN)
        Bit1: Read/Write, Si es 1 las paginas son marcadas con acceso de read/write
        Bit2: Cacheable,  Si es 1 la memoria es habilitada para ser almacenada en cache.
        Bit3: Global,     Si es 1 las paginas son marcadas como "Global" mediante el bit nG.
    R3: Dirección de tabla L1.
*/

_identiy_map_memory_range:
    PUSH {R4-R7, LR}

    //Reviso la alineacion de la direccion de inicio
    LDR R4, =0xFFF
    TST R0, R4
    BNE addr_not_aligned

    
    ADD R4, R1, R0 //R4: Ultima direccion que se busca mapear


    MOV R5, R2 //R5: Configuracion
    MOV R6, R0 //R6: Direccion desde donde paginar

    identity_map_loop:
        //Si me pase o ya llegue a la ultima direccion, termino el loop
        CMP R6, R4
        BGE identity_map_loop_end

        //Mapeo el bloque de 4KiB ubicado en R0
        MOV R1, R5 //R1: Configuracion
        MOV R0, R6 //R0: Direccion de bloque que se debe mapear
        BL _identy_map_small_page

        //Avanzo al siguiente bloque
        ADD R6, R6, #0x1000 //R6: Direccion de bloque que se debe mapear en el siguiente loop

        B identity_map_loop

    addr_not_aligned:
        MOV R0, #0
        B identity_map_end

    identity_map_loop_end:
        MOV R0, #1

    identity_map_end:

    POP {R4-R7, LR}
    BX LR

/*
Definicion de _identy_map_small_page

Crea una small page para paginar un bloque de 4KiB de memoria con un mapea
de identity mapping. Primero revisa si existe la tabla L2 en la ubicacion
correcta en L1. Si existe, agrega la entrada para un small page en la tabla
L2. Si aun no existe, crea una nueva tabla en donde apunte el puntero
"next_l2_table_addr" y avanza el puntero.

Parametros:
    R0: Direccion de bloque de 4K que se desea mapear (0x11122---)
    R1: Configuracion:
        Bit0: Ejecutable, Si es 1 las paginas no son marcadas como nunca ejecutable (XN)
        Bit1: Read/Write, Si es 1 las paginas son marcadas con acceso de read/write
        Bit2: Cacheable,  Si es 1 la memoria es habilitada para ser almacenada en cache.
        Bit3: Global,     Si es 1 las paginas son marcadas como "Global" mediante el bit nG.
*/

_identy_map_small_page:
    PUSH {R4-R7, LR}
    MOV R5, R1 //R5: Configuracion

    LDR R1, =0xFFFFF000
    AND R0, R0, R1 //R0: Direccion de bloque de 4K que se busca mapear

    LSR R1, R0, #20 //R1: Indice de tabla L1

    MOV R2, R3
    ADD R2, R2, R1, LSL#2 //R2: Direccion de la entrada de la tabla L1

    LDR R7, [R2] //R7: Entrada leida de la tabla L1
    
    AND R1, R7, #0b11 //R1: Ultimos 2 bits de la entrada de la tabla L1
    CMP R1, #0b01

    BEQ l2_table_found
    l2_table_not_found:
        //Si no se encuentra una tabla de L2, la crea
        LDR R1, =next_l2_table_addr
        LDR R7, [R1]//R7: Direccion de donde hay que crear la tabla L2

        ADD R4, R7, #0x3FC
        LDR R6, =0
        l2_table_fill_zero:
            STR R6, [R4]
            SUB R4, R4, #004
            CMP R4, R7
            BGE l2_table_fill_zero

        MOV R4, R7
        ORR R4, R4, #(TT_PAGE_TABLE | TT_PAGE_TABLE_NS) //R4: Entrada para la tabla L1 que hay que escribir

        STR R4, [R2] //Escribe la entrada en la tabla L1

        ADD R4, R7, #(256*4) //R4: Direccion de la ubicacion donde estará la siguiente tabla L2
        STR R4, [R1] //Actualizo next_l2_table_addr

        B set_l2_table_entry
    
    l2_table_found:
        LDR R2, =0xFFFFFC00
        AND R7, R7, R2 //R7: Direccion donde se encuentra la tabla L2

    set_l2_table_entry:
        LDR R1, =0x3FC
        AND R1, R1, R0, LSR#10
        ADD R7, R7, R1 // R7: Direccion de entrada para la tabla L2

        ORR R1, R0, #(TT_SMALL_PAGE | TT_SMALL_PAGE_AP_0 |TT_SMALL_PAGE_AP_1) //R1: Entrada de la tabla L2

        //Reviso propiedad de executable
        TST R5, #IDNTY_MAP_EXECUTABLE
        ORREQ R1, R1, #(TT_SMALL_PAGE_XN)
        
        //Reviso propiedad de read/write
        TST R5, #IDNTY_MAP_RW
        ORREQ R1, R1, #(TT_SMALL_PAGE_AP_2)
        
        //Reviso propiedad de cacheable
        TST R5, #IDNTY_MAP_CACHE_EN
        ORRNE R1, R1, #(TT_SMALL_PAGE_C)

        //Reviso propiedad de globalidad
        TST R5, #IDNTY_MAP_GLOBAL
        ORREQ R1, R1, #(TT_SMALL_PAGE_NG)

        STR R1, [R7] //Escribo la entrada de la tabla L2
   

    POP {R4-R7, LR}
    BX LR


.section .data
next_l2_table_addr: .word _L2_PAGE_TABLES_INIT 


.end
