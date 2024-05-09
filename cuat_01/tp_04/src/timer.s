.include "src/addr.s"


.section .kernel,"ax"@progbits

.global _timer0_enable

_timer0_enable:
    LDR R0, =(TIMER0_ADDR + TIMER_LOAD_OFFSET) //Para ticks de 10ms si el clock es de 32.768kHz
	LDR R1, =10000
	STR R1, [R0]

    LDR R0, =(TIMER0_ADDR + TIMER_CTRL_OFFSET)
	LDR R1, =0b11100000 //Enable. Enable interrupts. x1 Prescaler
	STR R1, [R0]

    BX LR

