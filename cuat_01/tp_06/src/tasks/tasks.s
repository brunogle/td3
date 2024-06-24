.section .text_kernel,"ax"@progbits

.global _task1, _task2

.section .text.task1
_task1:
    ADD R5, R5, #1

    MOV R0, #0
    SVC #0

    B _task1



.section .text.task2
_task2:
    ADD R6, R6, #1

    MOV R0, #0
    SVC #0

    B _task2




.section .data.task1
NOP
.section .bss.task1
NOP
.section .rodata.task1
NOP


.section .data.task2
NOP
.section .bss.task2
NOP
.section .rodata.task2
NOP

