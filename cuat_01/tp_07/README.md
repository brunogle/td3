# Descripción del proyecto

## Logica del kernel

El kernel ejecuta todas las tareas en una secuencia roundrobbin. Cada tarea se ejecuta hasta que ocurra alguno de los siguientes
eventos:

-  Se ejecute un syscall yield (`SVC` con `R0=0`)
-  Vence el timer: Si una tarea se ejecuta continuamente por mas de 100ms, entonces es parada por el scheduler

Cuando cambie de tarea, se pasará a ejecutar la siguiente tarea en la lista definida en `task_setup.s`. Una vez que se termino de ejecutar la ultima tarea en la lista, es scheduler evalua si todos los cambios de tarea occurrieron voluntariamente (por syscall). En el caso de que si, se considera que ninguna de las tareas requiere de mas tiempo de CPU, entonces el scheduler entrará en una tarea de sleep por 100ms y luego retomará denuevo con la primer tarea. En el caso de que una o mas tareas hayan sido interrumpidas, se considera que las tareas requieren de más atención y continua nuevamente con la primer imediatamente despues de la ultima tarea.


## Como agregar una tarea al SO

Los unicos archivos que se deben modificar si se desea agregar una tarea es `src/kernel/task_setup.s` y `src/user/tasks.ld`.

### Linkerscript

En `src/user/tasks.ld` se deben definir las nuevas secciones agregando las siguientes lineas dentro de `SECIONS { }`, cambiando `TASKNAME` con el nombre de la tarea.

```
    .text_TASKNAME : ALIGN(4K)
    {
        *(.text.TASKNAME);
    } >ram AT>rom
    _TASKNAME_TEXT_INIT = ADDR(.text_TASKNAME);
    _TASKNAME_TEXT_LOAD = LOADADDR(.text_TASKNAME);
    _TASKNAME_TEXT_SIZE = SIZEOF(.text_TASKNAME);

    .data_TASKNAME : ALIGN(4K)
    {
        *(.data.TASKNAME);
    } >ram AT>rom
    _TASKNAME_DATA_INIT = ADDR(.data_TASKNAME);
    _TASKNAME_DATA_LOAD = LOADADDR(.data_TASKNAME);
    _TASKNAME_DATA_SIZE = SIZEOF(.data_TASKNAME);

    .stack_TASKNAME : ALIGN(4K)
    {
        . += STACK_SIZE;
    } >ram
    _TASKNAME_STACK_INIT = ADDR(.stack_TASKNAME);
    _TASKNAME_STACK_SIZE = SIZEOF(.stack_TASKNAME);

    .bss_TASKNAME : ALIGN(4K)
    {
        *(.bss.TASKNAME*);
    } >ram
    _TASKNAME_BSS_INIT = ADDR(.bss_TASKNAME);
    _TASKNAME_BSS_SIZE = SIZEOF(.bss_TASKNAME);

    .rodata_TASKNAME : ALIGN(4K)
    {
        *(.rodata.TASKNAME*);
    } >ram AT>rom
    _TASKNAME_RODATA_INIT = ADDR(.rodata_TASKNAME);
    _TASKNAME_RODATA_LOAD = LOADADDR(.rodata_TASKNAME);
    _TASKNAME_RODATA_SIZE = SIZEOF(.rodata_TASKNAME);
```

Es importante respetar las ubicaciones en ROM y RAM y para cada tarea definir todas las secciones (text, data, bss, stack, rodata)

### Task Setup

En `src/user/task_setup.s` se deben agregar:


TODAS las direcciones a los arrays definididos en el archivo:

```
_list_task_text_init: .word ..., _TASKNAME_TEXT_INIT
_list_task_text_load: .word ..., _TASKNAME_TEXT_LOAD
_list_task_text_size: .word ..., _TASKNAME_TEXT_SIZE

_list_task_data_init: .word ..., _TASKNAME_DATA_INIT
_list_task_data_load: .word ..., _TASKNAME_DATA_LOAD
_list_task_data_size: .word ..., _TASKNAME_DATA_SIZE

_list_task_stack_init: .word ..., _TASKNAME_STACK_INIT
_list_task_stack_size: .word ..., _TASKNAME_STACK_SIZE

_list_task_bss_init: .word ..., _TASKNAME_BSS_INIT
_list_task_bss_size: .word ..., _TASKNAME_BSS_SIZE

_list_task_rodata_init: .word ..., _TASKNAME_RODATA_INIT
_list_task_rodata_load: .word ..., _TASKNAME_RODATA_LOAD
_list_task_rodata_size: .word ..., _TASKNAME_RODATA_SIZE

```

Los puntos de entrada:

```
_list_task_entrypoint: .word ..., _taskname

```

Agregar una sección para la tabla de paginación L1:

```
.align 14
TASKNAME_L1_PAGE_TABLES_INIT:
.space 0x4000
```

Agregar la dirección de la tabla L1 a:

```
_list_task_pagetables: .word ..., TASKNAME_L1_PAGE_TABLES_INIT
```

Aumentar `task_count` por 1.
```
task_count: .word [numero de tareas]
```
