# Descripción del proyecto


En este proyecto se habilita la paginación en modo identity mapping. El kernel escribe en memoria RAM, una tabla de nivel 1 y 4096 tablas de nivel 2, con direcciones para que se realice la conversión de direccion virtual a fisica y que no se produzcan cambios. Esto permite seguir ejecutando el codigo del kernel como si no hubiese habido ningun cambio. Se mantiene el timer 0 que actualiza R10 cada 10ms

## Archivos:
- `src/bootloader/bootloader.s`: Aca se encuentra el codigo de bootloader, las secciones definidas en este archivo se ejecutan sobre ROM. Es el punto de entrada del programa
- `src/bootloader/memcpy.s`: Aca se encuentra simplemente la funcion de memcpy para realizar la escritura en RAM. Las VMA de esta seccion tambien se encuentran en ROM
- `src/kernel/kernel.s`: En este archivo se encuentra el punto de inicio del kernel. Realiza llamadas a funciones para configurar distintas partes del sistema.
- `src/interrupt/handlers.s`: Handlers de las interrupciones y exepciones
- `src/interrupt/isr.s`: Solamente se encuentra aca la tabla ISR
- `src/interrupt/irq.s`: Subrutinas para habilitar las interrupciones IRQ
- `src/driver/gic.s`: Codigo para configurar el GIC
- `src/driver/timer.s`: Codigo para configurar el Timer 0
- `src/driver/mmu.s`: Codigo para configurar la MMU
- `src/paging/paging/s`: Subrutinas para realizar la escritura de las Translation Tables para el funcionamiento de la paginación
- `src/util/addr.s`: Aca se encuentran todos los .equ que especifican direcciones y mascaras de registros para poder configurar perifericos

# Ejecución

El make ahora incluye `make help` que explica las opciones de ejecutar el codigo:

**make all**   : Ensambla el binario

**make qemu**  : Ensambla el binario y lo corre en qemu

**make debug** : Ensambla el binario, lo corre en qemu y abre el ddd y ejecuta los comandos en gdb_init_ddd.txt

Opcionalmente, si se pasa EXCEPTIONS=0 en cualquier tarea, no se ejecutara codigo en ninguna exepcion.
Similar para IRQ=0 y FIQ=0

Este TP es el primero en incluir un directorio .vscode que permite el uso de la extensión "Native Debug" para poder debuggear dentro de Visual Studio Code.
El launch "Debug QEMU", compila el binario, ejecuta QEMU e inicializa el debugger. Terminar el launch task, cierra TODOS los procesos abiertos de qemu en el sistema.

 
