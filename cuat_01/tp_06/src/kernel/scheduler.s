.global _start_scheduler
.global _init_scheduler
.global _context_switch
.global _add_task
.global _sched_yield
.global _sched_force_context_switch

.include "src/cpu_defines.s"

.section .text.kernel


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

    LDR R2, =all_tasks_yielded
    MOV R1, #0x1
    STR R1, [R2]

    LDR LR, [R0, #(4*15)]


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
    R2: Direccion de stack

Retorna:
    R0: Direccion del TCB
*/
_add_task:
    MOV R4, R1

    LDR R3, =total_running_tasks
    LDR R5, [R3]

    LDR R1, =thread_control_blocks
    ADD R1, R1, R5, LSL#7
    /* Guarda en el LR del PCB el punto de comienzo de ejecucion de la tarea */
    
    STR R0, [R1, #(4*15)] //Guarda la direccion de inicio de la tarea
    STR R2, [R1, #(4*13)] //Guarda el stack pointer
    STR R4, [R1, #(4*17)] //Guarda la TTBR0

    ADD R5, R5, #1 //Incrementa el thread_control_blocks en 1
    STR R5, [R3]

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
    /*
    Almacena los registros R0-R12 y de paso obtiene
    la direccion de la TCB actual
    */    
    PUSH {R14}
    LDR R14, =current_task_conext_addr
    LDR R14, [R14]
    STMEA R14!, {R0-R12}
    POP {R14}
    LDR R0, =current_task_conext_addr
    LDR R0, [R0]
    //R0 : Direccion de TCB actual
        
    /*
    Almacena la direccion donde se detuvo la tarea (PC)
    */
    STR LR, [R0, #(4*15)]

    /*
    Cambia a modo SYS y guarda el modo de ejecucion
    */
    MRS R1, CPSR
    AND R1, R1, #0x1f
    CPS #SYS_MODE
    //R1: Bits de modo de CPSR

    /* Almacena los registros SP, LR, SPSR */
    MRS R2, SPSR
    STR SP, [R0, #(4*13)]
    STR LR, [R0, #(4*14)]
    STR R2, [R0, #(4*16)]

    /* Retoma el modo anteorior (IRQ o SVC) */
    MRS R2, CPSR
    BIC R2, R2, #0x1f
    ORR R2, R2, R1
    MSR CPSR, R2

    /* Encuentra la direccion del TCB de la siguiente tarea */
    PUSH {LR}
    BL _next_task
    POP {LR}
    //R0: current_task_conext_addr

    /* Recupera TTBR0 */
    LDR R3, [R0, #(4*17)]

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

    /*
    Cambia a modo SYS y guarda el modo de ejecucion
    */
    MRS R3, CPSR
    AND R3, R3, #0x1f
    CPS #SYS_MODE

    /* Recupera los registros SP, LR, SPSR */
    LDR SP, [R0, #(4*13)]
    LDR LR, [R0, #(4*14)]
    LDR R1, [R0, #(4*16)]
    MSR SPSR, R1
    MOV R1, LR

    /* Retoma el modo anteorior (IRQ o SVC) */
    MRS R2, CPSR
    BIC R2, R2, #0x1f
    ORR R2, R2, R3
    MSR CPSR, R2

    /* Recupera el valor de  */
    LDR LR, [R0, #(4*15)]

    /* Retoma el modo anteorior (IRQ o SVC) */
    PUSH {R14}

    MOV R14, R0
    LDMFD R14!, {R0-R12}

    POP {R14}
    MOVS PC, LR



    /* Copiar la pila al espacio de contexto de la tarea vieja */
    /* Cambiar TTBR0 para que apunte a nueva tabla */
    /* Cargar la pila con el espacio de contexto de la tarea nueva
    */

/*
Subrutina _sched_yield

*/
_sched_yield:
    B _context_switch

_sched_force_context_switch:
    PUSH {R0, R1}
    LDR R0, =current_task_id
    LDR R0, [R0]
    CMP R0, #0
    MOVNE R0, #0
    LDRNE R1, =all_tasks_yielded 
    STRNE R0, [R1]
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

    ADD R1, R1, #1 // Incrementa el task ID
    CMP R1,R3
    BEQ round_robin_ended
    round_robin_continues:
        STR R1, [R0]
        LDR R0, =thread_control_blocks
        ADD R0, R0, R1, LSL#7
        LDR R2, =current_task_conext_addr
        STR R0, [R2]
        BX LR
    
    round_robin_ended:
        LDR R3, =all_tasks_yielded
        LDR R2, [R3]
        CMP R2, #1
        MOVEQ R1, #0 //Si todas las tareas cedieron el control, puedo ir a sleep

        MOVNE R1, #1 //Si no, continuo de la tarea 1
        MOVNE R2, #0 //Seteo all_task_yielded en 1 nuevamente
        STRNE R2, [R3]

        STR R1, [R0]
        LDR R0, =thread_control_blocks
        ADD R0, R0, R1, LSL#7
        LDR R2, =current_task_conext_addr
        STR R0, [R2]

        BX LR



_sleep_task:
    NOP
    sleep_task_loop:
    WFI
    B sleep_task_loop

    


.section .bss

current_task_id: .word 0
current_task_conext_addr: .word 0
total_running_tasks: .word 0
all_tasks_yielded : .word 0

/*
TCB:
Espacio de contexto (R0-R12): 64 bytes (0-12)
Stack Pointer (SP/R13): 4 bytes (13)
Link Register (LR/R14): 4 bytes (14)
Program Counter (PC): 4 bytes (15)
CPSR: 4 bytes (16)
TTBR0: 4 bytes (17)

*/
thread_control_blocks:
    .space 128*4
