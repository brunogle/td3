# Descripción del proyecto

Este proyecto consiste de un sistema operativo básico que permite la ejecución concurrente de tareas.

El kernel fue implementado completamente en ARM Assembly.

Se utiliza paginación para aislar las tareas, pero todo el mapeo que se realiza es de identidad (Dir virtual = Dir fisica).

# Dependencias


## Para compilar
### ARM Toolchain
https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain

## Para Ejecutar
### QEMU
https://www.qemu.org/docs/master/index.html

## Para debugear
### GDB ARM
https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain

### Front end (opción A)
https://www.gnu.org/software/ddd/

### Front end (opcion B)
https://code.visualstudio.com/
https://marketplace.visualstudio.com/items?itemName=webfreak.debug


# Estructura del proyecto

## Bootloader: `src/bootloader`
Esta carpeta contiene el único código que se ejecuta directamente desde ROM. Tiene la función de copiar a RAM todos los datos del sistema operativo y del usuario.

## Código de kernel: `src/kernel`
Esta carpeta contiene todo el sistema operativo, no debe ser modificado por el usuario.
- `src/kernel/kernel.s` Contiene el punto de entrada del kernel y las subrutinas que inicializan las tareas en memoria (paginación, permisos, copia de ROM a RAM, inicialización del scheduler)
- `src/kernel/paging.s` Contiene las subrutinas con la lógica para escribir en memoria las tablas de paginación L1 y L2. Provee un nivel abstracción para poder cargar las páginas en memoria de forma más simple. Solamente soporta identity mapping.
- `src/kernel/scheduler.s` Contiene todo lo relacionado con el scheduler, incluyendo la lógica que determina la siguiente tarea que se debe ejecutar, una tarea de sleep que permite ahorrar energía si ninguna tarea requiere atención, el código para realizar un cambio de contexto y las subrutinas necesarias para utilizarlo.
- `src/kernel/config.s` Contiene definiciones que permiten cambiar el comportamiento del kernel.

## Código de usuario: `src/user`

- `src/user/task_setup.s` En este archivo se especifican todas las direcciones de memoria relacionadas con las tareas. Debe ser modificado por el usuario cuando desee agregar una tarea.
- `src/user/tasks.ld` Este linkerscript debe ser modificado por el usuario para agregar las secciones que se necesiten para las tareas.
- `src/user/tasks.s` Este archivo contiene tareas de ejemplo. Puede ser eliminado y remplazado por una estructura de archivos que le sea más útil al usuario.

# Lógica del scheduler

El kernel ejecuta todas las tareas en una secuencia "roundrobbin". Cada tarea se ejecuta hasta que ocurra alguno de los siguientes
eventos:

-  Se ejecute un syscall yield (`SVC` con `R0=0`)
-  Vence el timer: Si una tarea se ejecuta continuamente por más de 100ms (default), entonces es interrumpida por el scheduler para continuar con la ejecución de la siguiente tarea en la lista.

Cuando se cambie de tarea, se pasará a ejecutar la siguiente tarea en la lista definida en `task_setup.s`. Una vez que se terminó de ejecutar la última tarea en la lista, el scheduler evalúa si todos los cambios de tarea ocurrieron voluntariamente (por syscall). En el caso de que sí, se considera que ninguna de las tareas requiere de más tiempo de CPU, entonces el scheduler entrará en una tarea de sleep por 100ms y luego retomará con la primera tarea de la lista. En el caso de que una o más tareas hayan sido interrumpidas, se considera que las tareas requieren de más atención y continua con la primera tarea inmediatamente después de la última tarea sin pasar por el sleep.

# Como agregar una tarea al SO

Los únicos archivos que se deben modificar si se desea agregar una tarea son `src/kernel/task_setup.s` y `src/user/tasks.ld`.

## Linkerscript: `src/user/tasks.ld`

En `src/user/tasks.ld` se deben definir las nuevas secciones agregando las siguientes líneas dentro de `SECIONS { }`, cambiando `TASKNAME` por el nombre de la tarea.

```json
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

## Task Setup: `src/user/task_setup.s`

En `src/user/task_setup.s` se deben agregar:


- TODAS las direcciones a los arrays definiddos en el archivo:

```c
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

- Los puntos de entrada:

```c
_list_task_entrypoint: .word ..., _taskname

```

- Agregar una sección para la tabla de paginación L1:

```c
.align 14
TASKNAME_L1_PAGE_TABLES_INIT:
.space 0x4000
```

- Agregar la dirección de la tabla L1 a:

```c
_list_task_pagetables: .word ..., TASKNAME_L1_PAGE_TABLES_INIT
```

- Aumentar `task_count` por 1.

```c
task_count: .word [numero de tareas]
```


# Makefile

### Tareas:

`make`: Ensambla de todo el codigo incluido en src, escribe los objetos en `obj/` y linkea para producir `output.bin` y `output.elf` que contienen el SO y las tareas.

`make qemu`: Recompila el proyecto entero, y ejecuta el binario en QEMU con los argumentos especificados en la variable `QEMUFLAGS`.

`make debug`: Recompila el proyecto entero, lo ejecuta como en `make qemu` y inicializa DDD para debugear la ejecución.

`make clean`: Elimina las carpetas `obj/`, `lst/` y `bin/`

`make help`:  Imprime un mensaje de ayuda

### Argumentos opcionales:

`EXCEPTIONS=0` no se ejecutara el handler de ninguna excepción

`IRQ=0` no se ejecutara el handler de IRQ

`FIQ=0` no se ejecutara el handler de FIQ

`SVC=0` deshabilita SVC

`GEN_LISTS=1` genera archivos "lists"



# Debugging con VSCode+Native Debug (recomendado)

Para debugear con VSCode, se debe instalar la extensión "Native Debug" especificado en las dependencias.

Luego, se puede abrir la carpeta `cuat_01/tp_07` en VSCode y ejecutar la configuración de arranque "Debug QEMU".

Esta tarea ejecuta `make qemu` y conecta el front end de GDB de la extensión "Native Debug" al servidor de GDB de QEMU.

Para visualizar la ejecución de las tareas se pueden ubicar breakpoints en ellas, y comenzar la ejecución presionando F5.

# Debugging con DDD

Para debugear con DDD simplemente se puede ejecutar `make debug`
