.include "src/defines.s"

.section .text_kernel,"ax"@progbits

.global _timer0_10ms_tick_enable


/*
Subrutina _timer0_10ms_tick_enable

Configura y habilita el Timer0 para producir interrupciones cada 10ms
(asumiendo clock de 1MHz).
*/
_timer0_10ms_tick_enable:
    LDR R0, =(TIMER0_ADDR + TIMER_LOAD_OFFSET) //Para ticks de 10ms si el clock es de 1MHz
	LDR R1, =10000
	STR R1, [R0]

    LDR R0, =(TIMER0_ADDR + TIMER_CTRL_OFFSET)
	LDR R1, =0b11100000 //Enable. Enable interrupts. x1 Prescaler
	STR R1, [R0]

    BX LR

