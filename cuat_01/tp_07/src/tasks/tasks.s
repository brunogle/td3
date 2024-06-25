.section .text.kernel

.global _task1, _task2

.equ READING_AREA_SIZE, 0x10000

.section .text.task1
_task1:
    LDR R2, =task1_readingarea
    LDR R3, =task1_readingarea
    LDR R1, =READING_AREA_SIZE
    ADD R3, R3, R1
    LDR R1, =0x55AA55AA
    MOV R4, #1
    LDR R5, =memory_error_detected
    
    MOV R0, #1
    write_loop:
    CMP R2, R3
    BEQ end_write_loop
        SVC 0
        ADD R2, R2, #4
        B write_loop
    
    end_write_loop:

    LDR R1, =task1_readingarea
    MOV R2, R1
    MOV R0, #2

    read_loop:
    CMP R1, R3
    
    BEQ end_read_loop
        SVC #0
        CMP R0, R2
        LDRNE R4, [R5]
        ADD R1, R1, #4
        B read_loop

    end_read_loop:

    LDR R0, =num_memory_scans_performed
    LDR R1, [R0]
    ADD R1, R1, #1
    STR R1, [R0]

    MOV R0, #0
    SVC 0
    B _task1

.section .readingArea.task1
task1_readingarea:
.space 0x10000

.section .data.task1
memory_error_detected: .word 0
num_memory_scans_performed: .word 0

.section .bss.task1
NOP
.section .rodata.task1
NOP



.section .text.task2
_task2:

    LDR R1, =task2_readingarea
    LDR R4, =task2_readingarea
    LDR R3, =READING_AREA_SIZE
    ADD R4, R4, R3

    inv_mem_loop:
    CMP R1, R4
    BEQ end_inv_mem_loop

        MOV R0, #2
        SVC #0
        MOV R2, R1
        MVN R1, R0
        MOV R0, #1
        SVC #0
        ADD R1, R2, #4
        B inv_mem_loop
    
    end_inv_mem_loop:

    LDR R0, =num_mem_inversions_performed
    LDR R1, [R0]
    ADD R1, R1, #1
    STR R1, [R0]

    MOV R0, #0
    SVC #0

    B _task2

.section .readingArea.task2
task2_readingarea:
.space 0x10000

.section .data.task2
num_mem_inversions_performed: .word 0


.section .bss.task2
NOP
.section .rodata.task2
NOP

