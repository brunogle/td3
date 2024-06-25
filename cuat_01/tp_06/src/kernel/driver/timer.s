.include "src/cpu_defines.s"

.section .text.kernel

.global _timer0_10ms_tick_enable
.global SCHED_TICK_TIMER_LOAD

.equ SCHED_TICK_TIMER_LOAD, 15000 //100000=100ms




/*
Subrutina _timer0_10ms_tick_enable

Configura y habilita el Timer0 para producir interrupciones cada 10ms
(asumiendo clock de 1MHz).
*/
_timer0_10ms_tick_enable:
    LDR R0, =(TIMER0_ADDR + TIMER_LOAD_OFFSET) //Para ticks de 10ms si el clock es de 1MHz
	LDR R1, =SCHED_TICK_TIMER_LOAD
	STR R1, [R0]

    LDR R0, =(TIMER0_ADDR + TIMER_CTRL_OFFSET)
	LDR R1, =0b11100000 //Enable. Enable interrupts. x1 Prescaler
	STR R1, [R0]

    BX LR

