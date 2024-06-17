.section .text_kernel,"ax"@progbits

.global _task1, _task2


_task1:
    ADD R0, R0, #1
    B _task1

_task2:
    ADD R1, R1, #1
    B _task2
