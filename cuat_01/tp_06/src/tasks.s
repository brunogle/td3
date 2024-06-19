.section .text_kernel,"ax"@progbits

.global _task1, _task2

.section .text_kernel
_task1:
    ADD R5, R5, #1

    MOV R0, #0
    SVC #0

    B _task1

.section .text_task1
.section .data_task1
.section .bss_task1
.section .rodata_task1


.section .text_kernel
_task2:
    ADD R6, R6, #1

    MOV R0, #0
    SVC #0

    B _task2
.section .text_task2
.section .data_task2
.section .bss_task2
.section .rodata_task2
