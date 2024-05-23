.include "src/util/addr.s"

.equ L1_TABLE_SIZE, 256
.equ L2_TABLE_SIZE, 4096


.global _set_l2_small_page
.global _fill_l2_table_small_page
.global _fill_tables_identity_mapping

.section .kernel,"ax"@progbits



/*
Setea una pagina chica (4K) en una tabla L2

R0: Numero de tabla
R1: Numero de entrada
R2: Direccion fisica de la pagina
R3: Execute Never

*/

_set_l2_small_page:
    STMFD   SP!, {R0-R3, LR}

    LDR R4, =_L2_PAGE_TABLES_INIT
    ADD R4, R0, LSL#10
    ADD R4, R1, LSL#2
    ORR R2, R2, #(TT_SMALL_PAGE | TT_SMALL_PAGE_AP_0 | TT_SMALL_PAGE_TEX_1)
    CMP R3, #0
    BEQ set_l2_small_page_no_xn
        ORR R2, R2, #(TT_SMALL_PAGE_XN)
    set_l2_small_page_no_xn:
    STR R2, [R4]

    LDMFD   SP!, {R0-R3, LR}
    BX LR



/*
Setea una entrada de tabla de pagina en una tabla L1

R0: Numero de entrada
R1: Direccion fisica de la tabla
R2: PXN
*/

_set_l1_page_table:
    STMFD   SP!, {R0-R3, LR}

    LDR R3, =_L1_PAGE_TABLES_INIT
    ADD R3, R0, LSL#2
    ORR R1, R1, #(TT_PAGE_TABLE)
    CMP R2, #0
    BEQ set_l1_page_table_no_xn
        ORR R1, R1, #(TT_PAGE_TABLE_PXN)
    set_l1_page_table_no_xn:
    STR R1, [R3]

    LDMFD   SP!, {R0-R3, LR}
    BX LR

/*
Llena una tabla L2 con entradas de paginas chicas (4K).
Las direcciones de las paginas se llenan para corresponder a un identity mapping

R0: Numero de tabla
R1: Execute Never

*/

_fill_l2_table_small_page:
    STMFD   SP!, {R0-R3, LR}

    MOV R3, R1
    LDR R1, =255 //Contador de posicion en la tabla

    fill_l2_table_small_page_loop:

        MOV R2, R1, LSL#12
        ORR R2, R0, LSL#20
        BL _set_l2_small_page

    SUBS R1, R1, #1
    BGE fill_l2_table_small_page_loop

    LDMFD   SP!, {R0-R3, LR}
    BX LR


/*
Llena la tabla L1 con entradas apuntando a las tablas de L2

R0: Execute Never

*/
_fill_l1_table_page_table:
    STMFD   SP!, {R0-R3, LR}

    MOV R2, R0

    LDR R0, =4095 //Contador de posicion en la tabla


    fill_l1_table_page_table_loop:

        LDR R1, =_L2_PAGE_TABLES_INIT
        ADD R1, R0, LSL#10
        BL _set_l1_page_table

    SUBS R0, R0, #1
    BGE fill_l1_table_page_table_loop

    LDMFD   SP!, {R0-R3, LR}
    BX LR


/*
Llena las tablas en modo identiy mapping

R0: Execute Never

*/
_fill_tables_identity_mapping:
    STMFD   SP!, {R0-R3, LR}
    MOV R1, R0

    BL _fill_l1_table_page_table

    MOV R0, #4095

    fill_tables_identity_mapping_loop:

        BL _fill_l2_table_small_page

    SUBS R0, R0, #1
    BGE fill_tables_identity_mapping_loop

    LDMFD   SP!, {R0-R3, LR}
    BX LR

