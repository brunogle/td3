.include "src/addr.s"

.global _gic_enable

.section .kernel,"ax"@progbits

_gic_enable:
    LDR R0, =(GICC0_ADDR + GICC_PMR_OFFSET) //Mask de interrupciones en 0xF
	LDR R1, =0x000000F0
	STR R1, [R0]

    LDR R0, =(GICD0_ADDR + GICD_ISENABLER_OFFSET + 0x04) //Habilito interrupciones con ID36 (Timer 0 y 1)
	LDR R1, =0x00000010
	STR R1, [R0]

    LDR R0, =(GICC0_ADDR + GICC_CTLR_OFFSET) //Habilito el CPU Interface del GIC
	LDR R1, =0x00000001
	STR R1, [R0]

    LDR R0, =(GICD0_ADDR + GICD_CTLR_OFFSET) //Habilito el Distribuitor del GIC
	LDR R1, =0x00000001
	STR R1, [R0]

    BX LR