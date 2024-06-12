/*
=============================================
                    GIC
==============================================
*/

// Direcciones de modulos 

.equ GICC0_ADDR, 0x1E000000
.equ GICD0_ADDR, 0x1E001000
.equ GICC1_ADDR, 0x1E010000
.equ GICD1_ADDR, 0x1E011000
.equ GICC2_ADDR, 0x1E020000
.equ GICD2_ADDR, 0x1E021000
.equ GICC3_ADDR, 0x1E030000
.equ GICD3_ADDR, 0x1E031000

// Offsets de direccion de registros (deben ser sumados a una direccion de modulo)

.equ GICC_CTLR_OFFSET,  0x000
.equ GICC_PMR_OFFSET,   0x004
.equ GICC_BPR_OFFSET,   0x008
.equ GICC_IAR_OFFSET,   0x00C
.equ GICC_EOIR_OFFSET,  0x010
.equ GICC_RPR_OFFSET,   0x014
.equ GICC_HPPIR_OFFSET, 0x018


.equ GICD_CTLR_OFFSET,          0x000
.equ GICD_TYPER_OFFSET,         0x004
.equ GICD_ISENABLER_OFFSET,     0x100
.equ GICD_ICENABLER_OFFSET,     0x180
.equ GICD_ISPENDR_OFFSET,       0x200
.equ GICD_ICPENDR_OFFSET,       0x280
.equ GICD_ISACTIVER_OFFSET,     0x300
.equ GICD_IPRIORITYR_OFFSET,    0x400
.equ GICD_ITARGETSR_OFFSET,     0x800
.equ GICD_ICFGR_OFFSET,         0xC00
.equ GICD_SGIR_OFFSET,          0xF00

//Definiciones usadas para paginar los registros
.equ GIC_REGMAP_INIT, GICC0_ADDR
.equ GIC_REGMAP_SIZE, (GICD3_ADDR + GICD_SGIR_OFFSET - GIC_REGMAP_INIT)


/*
=============================================
                    Timers
==============================================
*/

// Direcciones de modulos

.equ TIMER0_ADDR, 0x10011000
.equ TIMER1_ADDR, 0x10011020
.equ TIMER2_ADDR, 0x10012000
.equ TIMER3_ADDR, 0x10012020
.equ TIMER4_ADDR, 0x10018000
.equ TIMER5_ADDR, 0x10018020
.equ TIMER6_ADDR, 0x10019000
.equ TIMER7_ADDR, 0x10019020

// Offsets de direccion de registros (deben ser sumados a una direccion de modulo)

.equ TIMER_LOAD_OFFSET,   0x00
.equ TIMER_VAL_OFFSET,    0x04
.equ TIMER_CTRL_OFFSET,   0x08
.equ TIMER_INTCLT_OFFSET, 0x0C
.equ TIMER_RIS_OFFSET,    0x10
.equ TIMER_MIS_OFFSET,    0x14
.equ TIMER_BGLOAD_OFFSET, 0x18

//Definiciones usadas para paginar los registros
.equ TIMER_REGMAP_INIT, TIMER0_ADDR
.equ TIMER_REGMAP_SIZE, (TIMER7_ADDR + TIMER_BGLOAD_OFFSET - TIMER_REGMAP_INIT)



/*
=============================================
        Entradas de Tablas de paginacion
==============================================
*/

// Small Page

.equ TT_SMALL_PAGE,         0x2

.equ TT_SMALL_PAGE_NG,      0x800
.equ TT_SMALL_PAGE_S,       0x400
.equ TT_SMALL_PAGE_AP_2,    0x200
.equ TT_SMALL_PAGE_TEX_2,   0x100
.equ TT_SMALL_PAGE_TEX_1,   0x80
.equ TT_SMALL_PAGE_TEX_0,   0x40
.equ TT_SMALL_PAGE_AP_1,    0x20
.equ TT_SMALL_PAGE_AP_0,    0x10
.equ TT_SMALL_PAGE_C,       0x8
.equ TT_SMALL_PAGE_B,       0x4
.equ TT_SMALL_PAGE_XN,      0x1

.equ TT_SMALL_PAGE_TEX_OFFSET,   8


// Page table entry

.equ TT_PAGE_TABLE,         0x1

.equ TT_PAGE_TABLE_SBZ,     0x10
.equ TT_PAGE_TABLE_NS,      0x8
.equ TT_PAGE_TABLE_PXN,     0x4

.equ TT_PAGE_TABLE_DOMAIN_OFFSET,   8



/*
=============================================
            Modos de operacion
==============================================
*/

.equ USR_MODE, 0x10
.equ FIQ_MODE, 0x11
.equ IRQ_MODE, 0x12
.equ SVC_MODE, 0x13
.equ ABT_MODE, 0x17
.equ UND_MODE, 0x1B
.equ SYS_MODE, 0x1F
.equ I_BIT,    0x80
.equ F_BIT,    0x40


