.global _init_scheduler
.global _context_switch
.global _add_task

.include "src/cpu_defines.s"

.section .text_kernel,"ax"@progbits
/*
Cambia de contexto
R0: Numero de tarea a la que cambiar
*/

_init_scheduler:
    MOV R0, #0
    LDR R1, =current_task_id
    STR R0, [R1]

    MOV R0, #2
    LDR R1, =total_running_tasks
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
*/
_add_task:
    
    /* Aumenta total_running_tasks en 1 */
    LDR R3, =total_running_tasks
    LDR R2, [R3]

    /* Guarda en el LR del PCB el punto de comienzo de ejecucion de la tarea */
    LDR R1, =thread_control_blocks
    ADD R1, R1, R2, LSL#9
    STR R0, [R1, #(4*14)]

    /* Usa el mismo TTBR0 por ahora */
    MRC P15, 0, R0, C2, C0, 0
    STR R0, [R1, #(4*16)]

    ADD R2, R2, #1
    STR R2, [R3]

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

    /* Almacena TTBR0 */
    MRC P15, 0, R1, C2, C0, 0
    STR R1, [R0, #8]

    PUSH {LR}
    BL _next_task
    POP {LR}
    //R0: current_task_conext_addr

    /* Recupera TTBR0 */
    LDR R1, [R0, #(4*16)]
    ISB
    MCR P15, 0, R1, C2, C0, 0
    ISB

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
Subrutina _next_swtich

Esta subrutina encuentra la siguiente tarea que se debe ejecutar
y retorna la dirección de su TCB.

Retorna:
    R0: Direccion del TCB de la siguiente tarea

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
    MOVEQ R1, #0
    //R1 : id de siguiente tarea
    STR R1, [R0]

    LDR R0, =thread_control_blocks
    ADD R0, R0, R1, LSL#9
    LDR R2, =current_task_conext_addr
    STR R0, [R2]

    BX LR


    

.section .data

current_task_id: .word 0
current_task_conext_addr: .word 0
total_running_tasks: .word 0


.section .bss
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

