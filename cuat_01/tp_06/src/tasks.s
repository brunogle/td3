.section .text_kernel,"ax"@progbits

.global _task1, _task2


_task1:
    ADD R5, R5, #1

    MOV R0, #0
    SVC #0

    B _task1

_task2:
    ADD R6, R6, #1

    MOV R0, #0
    SVC #0

    B _task2

