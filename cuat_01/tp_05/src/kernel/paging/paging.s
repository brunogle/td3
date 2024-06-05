.include "src/addr.s"

.global _identiy_map_memory_range


.section .text_kernel,"ax"@progbits


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
    R2: Ejecutable (Si es 0 las paginas son marcadas como nunca ejecutable (XN)
                    si no es 0, las paginas son marcadas como ejecutable)
Retorna:
    R0: 1 si se realizo exitosamente, 0 si no.

*/

_identiy_map_memory_range:
    STMFD   SP!, {LR}

    //Reviso la alineacion de la direccion de inicio
    LDR R3, =0xFFF
    TST R0, R3
    BNE addr_not_aligned

    
    ADD R4, R1, R0 //R4: Ultima direccion que se busca mapear

    LDR R3, =0x1000

    MOV R1, R2 //R1: Ejecutable

    identity_map_loop:
        //Si me pase o ya llegue a la ultima direccion, termino el loop
        CMP R0, R4
        BGE identity_map_loop_end

        //Mapeo el bloque de 4KiB ubicado en R0
        BL _identy_map_small_page

        //Avanzo al siguiente bloque
        ADD R0, R0, R3

        B identity_map_loop

    addr_not_aligned:
        MOV R0, #0
        B identity_map_end

    identity_map_loop_end:
        MOV R0, #1

    identity_map_end:

    LDMFD   SP!, {LR}
    BX LR

/*
Definicion de _identy_map_small_page

Crea una small page para paginar un bloque de 4KiB de memoria con un mapea
de identity mapping. Primero revisa si existe la tabla L2 en la ubicacion
correcta en L1. Si existe, agrega la entrada para un small page en la tabla
L2. Si aun no existe, crea una nueva tabla en donde apunte el puntero
"next_l2_table_addr" y avanza el puntero.

R0: Direccion de bloque de 4K que se desea mapear (0x11122---)
R2: Ejecutable (Si es 0 la pagina es marcada como nunca ejecutable (XN)
                si no es 0, la pagina es marcada como ejecutable)
*/

_identy_map_small_page:
    STMFD   SP!, {R0-R3, LR}
    MOV R5, R1 //R5: Ejecutable

    LDR R1, =0xFFFFF000
    AND R0, R0, R1 //R0: Direccion de bloque de 4K que se busca mapear

    LSR R1, R0, #20 //R1: Indice de tabla L1

    LDR R2, =_L1_PAGE_TABLES_INIT
    ADD R2, R2, R1, LSL#2 //R2: Direccion de la entrada de la tabla L1

    LDR R3, [R2] //R3: Entrada leida de la tabla L1
    
    AND R1, R3, #0b11 //R1: Ultimos 2 bits de la entrada de la tabla L1
    CMP R1, #0b01

    BEQ l2_table_found
    l2_table_not_found:
        //Si no se encuentra una tabla de L2, la crea
        LDR R1, =next_l2_table_addr
        LDR R3, [R1]//R3: Direccion de donde hay que crear la tabla L2

        ADD R4, R3, #0x3FC
        LDR R6, =0
        l2_table_fill_zero:
            STR R6, [R4]
            SUB R4, R4, #004
            CMP R4, R3
            BGE l2_table_fill_zero

        MOV R4, R3
        ORR R4, R4, #(TT_PAGE_TABLE | TT_PAGE_TABLE_NS) //R4: Entrada para la tabla L1 que hay que escribir

        STR R4, [R2] //Escribe la entrada en la tabla L1

        ADD R4, R3, #(256*4) //R4: Direccion de la ubicacion donde estará la siguiente tabla L2
        STR R4, [R1] //Actualizo next_l2_table_addr

        B set_l2_table_entry
    
    l2_table_found:
        LDR R2, =0xFFFFFC00
        AND R3, R3, R2 //R3: Direccion donde se encuentra la tabla L2

    set_l2_table_entry:
        LDR R1, =0x3FC
        AND R1, R1, R0, LSR#10
        ADD R3, R3, R1 // R3: Direccion de entrada para la tabla L2


        ORR R1, R0, #(TT_SMALL_PAGE | TT_SMALL_PAGE_AP_0 |TT_SMALL_PAGE_AP_1) //R1: Entrada de la tabla L2

        CMP R5, #0
        BNE executable_page
            ORR R1, R1, #(TT_SMALL_PAGE_XN)
        executable_page:

        STR R1, [R3] //Escribo la entrada de la tabla L2

    LDMFD   SP!, {R0-R3, LR}
    BX LR


.section .data
next_l2_table_addr: .word _L2_PAGE_TABLES_INIT 


.end
