.global _start_scheduler
.global _init_scheduler
.global _context_switch
.global _add_task
.global _switch_to_sleep_task

.include "src/cpu_defines.s"

.section .text_kernel,"ax"@progbits


_init_scheduler:
    PUSH {LR}

    # La tarea 0 es la tarea de sleep
    LDR R1, =_L1_PAGE_TABLES_INIT
    LDR R0, =_sleep_task
    BL _add_task

	//Preparo count y habilito timer
	LDR R10,=0
	BL _timer0_10ms_tick_enable

    POP {LR}
    BX LR

_start_scheduler:
    MOV R0, #0
    LDR R1, =current_task_id
    STR R0, [R1]

    LDR R0, =thread_control_blocks
    LDR R1, =current_task_conext_addr
    STR R0, [R1]

    LDR LR, [R0, #(4*14)]


    MOV R0, #0
    MOV R1, #0
    MOV R2, #0
    MOV R3, #0
    MOV R4, #0
    MOV R5, #0
    MOV R6, #0
    MOV R7, #0
    MOV R8, #0
    MOV R9, #0
    MOV R10, #0
    MOV R11, #0
    MOV R12, #0
    BX LR


/*
Subrutina _add_task

Parametros:
    R0: Direccion de inicio de la tarea
    R1: TTBR0

Retorna:
    R0: Direccion del TCB
*/
_add_task:
    MOV R4, R1

    /* Aumenta total_running_tasks en 1 */
    LDR R3, =total_running_tasks
    LDR R2, [R3]

    /* Guarda en el LR del PCB el punto de comienzo de ejecucion de la tarea */
    LDR R1, =thread_control_blocks
    ADD R1, R1, R2, LSL#7
    STR R0, [R1, #(4*14)]

    STR R4, [R1, #(4*16)]

    ADD R2, R2, #1
    STR R2, [R3]

    MOV R0, R1

    BX LR



/*
Subrutina _context_switch

Cambia a la siguiente tarea proporcionada por la
subrutina _next_task.
Esta tarea no retorna nunca. Sino, que salta directamente
a la tarea nueva que se va a ejecutar.

Parametros:
    R0: Direccion del contexto de la tarea nueva

*/


_context_switch:    
    /* Almacena los registros R0-R12 */    
    PUSH {R14}
    LDR R14, =current_task_conext_addr
    LDR R14, [R14]
    STMEA R14!, {R0-R12}
    MOV R0, R14
    POP {R14}

    /* Almacena los registros SP, LR, SPSR */
    CPS #SYS_MODE
    STR SP, [R0]
    STR LR, [R0, #4]
    MRS R1, SPSR
    STR R1, [R0]
    CPS #IRQ_MODE


    PUSH {LR}
    BL _next_task
    POP {LR}
    //R0: current_task_conext_addr

    /* Recupera TTBR0 */
    LDR R3, [R0, #(4*16)]

    //Cambio ASID a 0
    MRC P15, 0, R2, C13, C0, 1
    BIC R2, R2, #0xFF
    MCR P15, 0, R2, C13, C0, 1

    //Carga TTBR0 de la tarea nueva
    ISB
    MCR P15, 0, R3, C2, C0, 0
    ISB

    //Cambia ASID al task id de la nueva tarea
    MRC P15, 0, R2, C13, C0, 1
    BIC R2, R2, #0xFF
    AND R1, R1, #0xFF
    ORR R2, R2, R1
    MCR P15, 0, R2, C13, C0, 1


    /* Recupera los registros SP, LR, SPSR */
    CPS #SYS_MODE
    LDR SP, [R0, #(4*13)]
    LDR LR, [R0, #(4*14)]
    LDR R1, [R0, #(4*15)]
    MSR SPSR, R1
    MOV R1, LR
    CPS #IRQ_MODE

    MOV LR, R1
    MOV SP, R0
    LDMFD SP!, {R0-R12}
    
    MOVS PC, LR



    /* Copiar la pila al espacio de contexto de la tarea vieja */
    /* Cambiar TTBR0 para que apunte a nueva tabla */
    /* Cargar la pila con el espacio de contexto de la tarea nueva
    */

/*
Subrutina _switch_to_sleep_task

*/
_switch_to_sleep_task:
    PUSH {R0, R1}
    MOV R0, #1
    LDR R1, =sleep_mode
    STR R0, [R1]
    POP {R0, R1}
    B _context_switch


/*
Subrutina _next_swtich

Esta subrutina encuentra la siguiente tarea que se debe ejecutar
y retorna la dirección de su TCB.

Retorna:
    R0: Direccion del TCB de la siguiente tarea
    R1: Task ID de la tarea nueva
*/
_next_task:
    LDR R0, =current_task_id
    LDR R1, [R0]
    LDR R2, =total_running_tasks
    LDR R3, [R2]

    //R0: =current_task_id
    //R1: id de tarea actual
    //R2: =total_running_tasks
    //R3: cantidad total de tareas

    LDR R4, =sleep_mode
    LDR R4, [R4]
    CMP R4, #0
    
    BNE voluntary_context_switch

    unvoluntary_context_switch:
        // Siguiente tarea en el ciclo:
        ADD R1, R1, #1 // Incrementa el task ID
        CMP R1,R3
        MOVEQ R1, #1
        STR R1, [R0]

        LDR R0, =thread_control_blocks
        ADD R0, R0, R1, LSL#7
        LDR R2, =current_task_conext_addr
        STR R0, [R2]

        BX LR

    voluntary_context_switch:

        // Siguiente tarea en el ciclo:
        ADD R1, R1, #1 // Incrementa el task ID
        CMP R1,R3
        MOVEQ R1, #0
        STR R1, [R0]

        LDR R0, =thread_control_blocks
        ADD R0, R0, R1, LSL#7
        LDR R2, =current_task_conext_addr
        STR R0, [R2]

        MOV R1, #0
        LDR R2, =sleep_mode
        STR R1, [R2]
        BX LR
        
    //R1 : id de siguiente tarea



_sleep_task:
    NOP
    sleep_task_loop:
    WFI
    B sleep_task_loop

    


.section .bss

current_task_id: .word 0
current_task_conext_addr: .word 0
total_running_tasks: .word 0
sleep_mode: .word 0

/*
TCB:
Espacio de contexto (R0-R12): 64 bytes
Stack Pointer (SP/R13): 4 bytes 
Link Register (LR/R14): 4 bytes
CPSR: 4 bytes
TTBR0: 4 bytes
PID: 4 bytes
*/
thread_control_blocks:
    .space 128*4
