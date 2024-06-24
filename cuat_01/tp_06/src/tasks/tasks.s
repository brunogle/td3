.section .text_kernel,"ax"@progbits

.global _task1, _task2

.section .text.task1
_task1:
    ADD R5, R5, #1

    LDR R0, =test1
    STR R5, [R0]

    MOV R0, #0
    SVC #0

    B _task1


.section .data.task1
test1: .word 0
NOP
.section .bss.task1
NOP
.section .rodata.task1
NOP



.section .text.task2
_task2:
    ADD R6, R6, #1

    LDR R0, =test2
    STR R6, [R0]

    MOV R0, #0
    SVC #0

    B _task2


.section .data.task2
test2: .word 0

NOP
.section .bss.task2
NOP
.section .rodata.task2
NOP

