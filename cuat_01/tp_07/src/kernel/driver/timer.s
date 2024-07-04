.include "src/kernel/config.s"

.section .text.kernel

.global _timer0_tick_enable



/*
Subrutina _timer0_tick_enable

Configura y habilita el Timer0 para producir interrupciones.
*/
_timer0_tick_enable:
    LDR R0, =(TIMER0_ADDR + TIMER_LOAD_OFFSET)
	LDR R1, =SCHED_TICK_TIMER_LOAD
	STR R1, [R0]

    LDR R0, =(TIMER0_ADDR + TIMER_CTRL_OFFSET)
	LDR R1, =0b11100000 //Enable. Enable interrupts. x1 Prescaler
	STR R1, [R0]

    BX LR

