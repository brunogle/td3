.section .text.kernel

.global _task1, _task2

.section .text.task1
_task1:
    LDR R0, =_TASK1_READINGAREA_INIT
    LDR R1, =_TASK1_READINGAREA_INIT
    LDR R2, =_TASK1_READINGAREA_SIZE
    ADD R1, R1, R2
    LDR R2, =_TASK1_READINGAREA_INIT
    MOV R4, #1
    LDR R5, =memory_error_detected
    
    write_loop:
    CMP R0, R1
    BEQ end_write_loop
        STR R2, [R0]
        ADD R0, R0, #4
        B write_loop
    
    end_write_loop:

    LDR R0, =task1_readingarea


    read_loop:
    CMP R0, R1
    BEQ end_read_loop
        LDR R3, [R0]
        CMP R2, R3
        LDRNE R4, [R5]
        ADD R0, R0, #4
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




.section .text.task2
_task2:

    LDR R0, =_TASK2_READINGAREA_INIT
    LDR R1, =_TASK2_READINGAREA_INIT
    LDR R2, =_TASK2_READINGAREA_SIZE
    ADD R1, R1, R2

    inv_mem_loop:
    CMP R0, R1
    BEQ end_inv_mem_loop
        LDR R2, [R0]
        MVN R2, R2
        STR R2, [R0]
        ADD R0, R0, #4
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
